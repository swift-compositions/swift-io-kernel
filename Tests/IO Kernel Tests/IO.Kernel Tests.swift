import IO_Kernel_Test_Support
import Testing

@Suite("IO")
private struct `Test` {
    @Suite struct `Unit` {}
    @Suite struct `Edge Case` {}
    @Suite struct `Integration` {}
    @Suite(.serialized) struct `Performance` {}
}

private struct TrivialCapabilities: Sendable {
    let tag: Int
}

private struct TaggedCapabilities<Tag>: Sendable {
    let marker: Int
}

private enum Client {}

extension Test.Unit {

    @Test
    func `IO bundles capabilities and runner`() {
        let caps = TrivialCapabilities(tag: 42)
        let io = IO<TrivialCapabilities>(capabilities: caps, runner: .unimplemented)
        #expect(io.capabilities.tag == 42)
    }

    @Test
    func `IO is Sendable across task boundaries when capabilities are Sendable`() async {
        let io = IO<TrivialCapabilities>(
            capabilities: TrivialCapabilities(tag: 1),
            runner: .unimplemented
        )
        let tag = await Task { io.capabilities.tag }.value
        #expect(tag == 1)
    }

    @Test
    func `convenience initializer supplies an unimplemented runner`() {
        let io = IO<TrivialCapabilities>(capabilities: TrivialCapabilities(tag: 7))
        #expect(io.capabilities.tag == 7)
    }
}

extension Test.`Edge Case` {

    @Test
    func `IO is generic over arbitrary Sendable capability types`() {
        let io = IO<TaggedCapabilities<Client>>(
            capabilities: TaggedCapabilities<Client>(marker: 99),
            runner: .unimplemented
        )
        #expect(io.capabilities.marker == 99)
    }
}
