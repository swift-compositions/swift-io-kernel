public import IO

#if !hasFeature(Embedded)
extension IO.Kernel {
    @safe
    public struct Runner: Sendable {
        public let executor: @Sendable () -> UnownedSerialExecutor
        public let shutdown: @Sendable () async -> Void

        public init(
            executor: @Sendable @escaping () -> UnownedSerialExecutor,
            shutdown: @Sendable @escaping () async -> Void
        ) {
            unsafe self.executor = executor
            self.shutdown = shutdown
        }
    }
}
#endif
