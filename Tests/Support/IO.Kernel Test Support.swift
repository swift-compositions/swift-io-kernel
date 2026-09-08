public import IO_Kernel

extension IO.Kernel.Runner {

    public static var unimplemented: IO.Kernel.Runner {
        unsafe IO.Kernel.Runner(
            executor: { fatalError("IO.Kernel.Runner.unimplemented.executor() was called") },
            shutdown: { fatalError("IO.Kernel.Runner.unimplemented.shutdown() was called") }
        )
    }
}

extension IO.Kernel {

    public init(capabilities: Capabilities) {
        self.init(capabilities: capabilities, runner: .unimplemented)
    }
}
