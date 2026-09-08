public import IO

extension IO {
    public struct Kernel<Capabilities: Sendable>: Sendable {
        public let capabilities: Capabilities
        public let runner: Runner

        public init(capabilities: Capabilities, runner: Runner) {
            self.capabilities = capabilities
            self.runner = runner
        }
    }
}
