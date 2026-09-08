import IO_Kernel_Test_Support
import Testing

private enum Server {}

extension Server {
    struct Address: Sendable, Equatable {
        let host: String
        let port: UInt16
    }

    struct Listener: Sendable, Equatable {
        let raw: Int32
    }

    struct Connection: Sendable, Equatable {
        let raw: Int32
        let peer: Server.Address
    }

    enum Error: Swift.Error, Sendable, Equatable {
        case portInUse
        case notBound
    }
}

extension Server {
    struct Capabilities: Sendable {
        let bind: @Sendable (Server.Address) async throws(Server.Error) -> Server.Listener
        let listen: @Sendable (borrowing Server.Listener, Int) async throws(Server.Error) -> Void
        let accept:
            @Sendable (borrowing Server.Listener) async throws(Server.Error) -> Server.Connection
        let close: @Sendable (consuming Server.Listener) async -> Void
    }
}

extension Server {

    @Suite("Server Usage (swift-server)")
    struct `Test` {
        @Suite struct `Unit` {}
        @Suite struct `Edge Case` {}
        @Suite struct `Integration` {}
        @Suite(.serialized) struct `Performance` {}
    }
}

private actor Recorder {
    var calls: [String] = []
}

extension Recorder {
    func log(_ entry: String) { calls.append(entry) }
    func snapshot() -> [String] { calls }
}

private func fake(
    recorder: Recorder,
    acceptedPeer: Server.Address
) -> IO.Kernel<Server.Capabilities> {
    let caps = Server.Capabilities(
        bind: { address throws(Server.Error) in
            await recorder.log("bind(\(address.host):\(address.port))")
            return Server.Listener(raw: 7)
        },
        listen: { listener, backlog throws(Server.Error) in
            await recorder.log("listen(listener: \(listener.raw), backlog: \(backlog))")
        },
        accept: { listener throws(Server.Error) in
            await recorder.log("accept(listener: \(listener.raw))")
            return Server.Connection(raw: listener.raw &+ 100, peer: acceptedPeer)
        },
        close: { listener in
            await recorder.log("close(listener: \(listener.raw))")
        }
    )
    return IO.Kernel(capabilities: caps)
}

extension Server.Test.Integration {

    @Test
    func `server lifecycle: bind → listen → accept → close`() async throws {
        let recorder = Recorder()
        let peer = Server.Address(host: "client.example", port: 54321)
        let io = fake(recorder: recorder, acceptedPeer: peer)

        let listener = try await io.capabilities.bind(Server.Address(host: "0.0.0.0", port: 8080))
        try await io.capabilities.listen(listener, 128)
        let connection = try await io.capabilities.accept(listener)
        #expect(connection.peer == peer)
        await io.capabilities.close(listener)

        let calls = await recorder.snapshot()
        #expect(
            calls == [
                "bind(0.0.0.0:8080)",
                "listen(listener: 7, backlog: 128)",
                "accept(listener: 7)",
                "close(listener: 7)",
            ]
        )
    }

    @Test
    func `TCA26 shared-executor pattern compiles`() {

        let caps = Server.Capabilities(
            bind: { _ throws(Server.Error) in Server.Listener(raw: 1) },
            listen: { _, _ throws(Server.Error) in },
            accept: { _ throws(Server.Error) in
                Server.Connection(raw: 2, peer: Server.Address(host: "", port: 0))
            },
            close: { _ in }
        )
        let io = IO.Kernel(capabilities: caps)
        _ = io.runner
    }
}
