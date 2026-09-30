import IO_Kernel_Test_Support
import Testing

private enum Socket {}

extension Socket {
    struct Descriptor: Sendable, Equatable {
        let raw: Int32
    }

    struct Address: Sendable, Equatable {
        let host: Swift.String
        let port: UInt16
    }

    enum Error: Swift.Error, Sendable, Equatable {
        case refused
        case reset
        case timeout
    }
}

extension Socket {
    struct Capabilities: Sendable {
        let connect:
            @Sendable (borrowing Socket.Descriptor, Socket.Address) async throws(Socket.Error) ->
                Void
        let accept:
            @Sendable (borrowing Socket.Descriptor) async throws(Socket.Error) -> Socket.Descriptor
        let send: @Sendable (borrowing Socket.Descriptor, Int) async throws(Socket.Error) -> Int
        let recv: @Sendable (borrowing Socket.Descriptor, Int) async throws(Socket.Error) -> Int
        let shutdown: @Sendable (borrowing Socket.Descriptor) async throws(Socket.Error) -> Void
        let close: @Sendable (consuming Socket.Descriptor) async -> Void
    }
}

extension Socket {

    @Suite("Socket Usage (swift-sockets)")
    struct `Test` {
        @Suite struct `Unit` {}
        @Suite struct `Edge Case` {}
        @Suite struct `Integration` {}
        @Suite(.serialized) struct `Performance` {}
    }
}

private actor Recorder {
    var calls: [Swift.String] = []
}

extension Recorder {
    func log(_ entry: Swift.String) { calls.append(entry) }
    func snapshot() -> [Swift.String] { calls }
}

private func fake(recorder: Recorder) -> IO<Socket.Capabilities> {
    let caps = Socket.Capabilities(
        connect: { fd, addr throws(Socket.Error) in
            await recorder.log("connect(fd: \(fd.raw), \(addr.host):\(addr.port))")
        },
        accept: { fd throws(Socket.Error) in
            await recorder.log("accept(fd: \(fd.raw))")
            return Socket.Descriptor(raw: fd.raw &+ 1)
        },
        send: { fd, n throws(Socket.Error) in
            await recorder.log("send(fd: \(fd.raw), n: \(n))")
            return n
        },
        recv: { fd, n throws(Socket.Error) in
            await recorder.log("recv(fd: \(fd.raw), n: \(n))")
            return n
        },
        shutdown: { fd throws(Socket.Error) in
            await recorder.log("shutdown(fd: \(fd.raw))")
        },
        close: { fd in
            await recorder.log("close(fd: \(fd.raw))")
        }
    )
    return IO(capabilities: caps)
}

extension Socket.Test.Integration {

    @Test
    func `client-style socket sequence: connect, send, recv, close`() async throws {
        let recorder = Recorder()
        let io = fake(recorder: recorder)

        let sock = Socket.Descriptor(raw: 5)
        try await io.capabilities.connect(sock, Socket.Address(host: "example.com", port: 443))
        _ = try await io.capabilities.send(sock, 128)
        _ = try await io.capabilities.recv(sock, 4096)
        await io.capabilities.close(sock)

        let calls = await recorder.snapshot()
        #expect(
            calls == [
                "connect(fd: 5, example.com:443)",
                "send(fd: 5, n: 128)",
                "recv(fd: 5, n: 4096)",
                "close(fd: 5)",
            ]
        )
    }

    @Test
    func `accept returns a fresh descriptor — no ready+raw_accept pattern`() async throws {
        let recorder = Recorder()
        let io = fake(recorder: recorder)

        let listener = Socket.Descriptor(raw: 3)
        let accepted = try await io.capabilities.accept(listener)
        #expect(accepted == Socket.Descriptor(raw: 4))

        let calls = await recorder.snapshot()

        #expect(calls == ["accept(fd: 3)"])
    }
}
