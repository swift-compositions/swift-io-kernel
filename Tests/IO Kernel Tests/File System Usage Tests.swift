import IO_Kernel_Test_Support
import Testing

private enum File {}

extension File {
    struct Path: Sendable, Equatable {
        let raw: String
    }

    struct Descriptor: Sendable, Equatable {
        let raw: Int32
    }

    struct Flags: Sendable, Equatable {
        let raw: Int32
    }

    struct Info: Sendable, Equatable {
        let size: UInt64
    }

    enum Error: Swift.Error, Sendable, Equatable {
        case notFound
        case permissionDenied
    }
}

extension File.Flags {
    fileprivate static let readOnly = File.Flags(raw: 0)
    fileprivate static let readWrite = File.Flags(raw: 2)
}

extension File {
    struct Capabilities: Sendable {
        let open: @Sendable (File.Path, File.Flags) async throws(File.Error) -> File.Descriptor
        let close: @Sendable (consuming File.Descriptor) async -> Void
        let read: @Sendable (borrowing File.Descriptor, Int) async throws(File.Error) -> Int
        let write: @Sendable (borrowing File.Descriptor, Int) async throws(File.Error) -> Int
        let stat: @Sendable (File.Path) async throws(File.Error) -> File.Info
        let unlink: @Sendable (File.Path) async throws(File.Error) -> Void
        let rename: @Sendable (File.Path, File.Path) async throws(File.Error) -> Void
    }
}

extension File {

    @Suite("File System Usage (swift-file-system)")
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

private func fake(recorder: Recorder) -> IO.Kernel<File.Capabilities> {
    let caps = File.Capabilities(
        open: { path, flags throws(File.Error) in
            await recorder.log("open(\(path.raw), flags: \(flags.raw))")
            return File.Descriptor(raw: 42)
        },
        close: { fd in
            await recorder.log("close(fd: \(fd.raw))")
        },
        read: { fd, n throws(File.Error) in
            await recorder.log("read(fd: \(fd.raw), n: \(n))")
            return n
        },
        write: { fd, n throws(File.Error) in
            await recorder.log("write(fd: \(fd.raw), n: \(n))")
            return n
        },
        stat: { path throws(File.Error) in
            await recorder.log("stat(\(path.raw))")
            return File.Info(size: 1024)
        },
        unlink: { path throws(File.Error) in
            await recorder.log("unlink(\(path.raw))")
        },
        rename: { from, to throws(File.Error) in
            await recorder.log("rename(\(from.raw) -> \(to.raw))")
        }
    )
    return IO.Kernel(capabilities: caps)
}

extension File.Test.Integration {

    @Test
    func `full read lifecycle: open → read → close`() async throws {
        let recorder = Recorder()
        let io = fake(recorder: recorder)
        let path = File.Path(raw: "/tmp/data.txt")

        let fd = try await io.capabilities.open(path, .readOnly)
        #expect(fd == File.Descriptor(raw: 42))
        _ = try await io.capabilities.read(fd, 4096)
        await io.capabilities.close(fd)

        let calls = await recorder.snapshot()
        #expect(
            calls == [
                "open(/tmp/data.txt, flags: 0)",
                "read(fd: 42, n: 4096)",
                "close(fd: 42)",
            ]
        )
    }

    @Test
    func `path-based ops are first-class — no fd involved`() async throws {
        let recorder = Recorder()
        let io = fake(recorder: recorder)
        let path = File.Path(raw: "/tmp/old.txt")

        let info = try await io.capabilities.stat(path)
        #expect(info.size == 1024)
        try await io.capabilities.rename(path, File.Path(raw: "/tmp/new.txt"))
        try await io.capabilities.unlink(File.Path(raw: "/tmp/new.txt"))

        let calls = await recorder.snapshot()
        #expect(
            calls == [
                "stat(/tmp/old.txt)",
                "rename(/tmp/old.txt -> /tmp/new.txt)",
                "unlink(/tmp/new.txt)",
            ]
        )
    }
}
