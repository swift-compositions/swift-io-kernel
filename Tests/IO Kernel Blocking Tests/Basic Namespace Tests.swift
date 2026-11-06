import IO_Kernel_Test_Support
import Testing

enum `Basic Tests` {}

extension `Basic Tests` {
    @Suite(.timeLimit(.minutes(1)))
    struct `Test` {
        @Suite struct `Unit` {}
        @Suite struct `Edge Case` {}
        @Suite struct `Integration` {}
        @Suite(.serialized) struct `Performance` {}
    }
}

extension `Basic Tests`.`Test`.Unit {
    @Test
    func `Basic namespace exists`() {

    }
}
