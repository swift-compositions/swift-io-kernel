public import IO_Kernel

extension IO.Runner {

    public static var unimplemented: IO.Runner {
        unsafe IO.Runner(
            executor: { fatalError("IO.Runner.unimplemented.executor() was called") },
            shutdown: { fatalError("IO.Runner.unimplemented.shutdown() was called") }
        )
    }
}

extension IO {

    public init(capabilities: Capabilities) {
        self.init(capabilities: capabilities, runner: .unimplemented)
    }
}
