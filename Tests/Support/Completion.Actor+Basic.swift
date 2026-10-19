#if !os(Windows)

    public import IO_Kernel
    public import Kernel
    public import Memory
    public import Span

    extension Completion.Actor {

        public func read(
            from fd: borrowing Kernel.Descriptor,
            into buffer: Span.Raw.Mutable
        ) async throws(Completion.Failure) -> Int {
            let raw = unsafe buffer.base.nonNull

            let descriptor: Kernel.Descriptor?
            do throws(Kernel.Descriptor.Duplicate.Error) {
                descriptor = try Kernel.Descriptor.Duplicate.duplicate(fd)
            } catch {
                throw error.completionFailure
            }

            guard let base = raw.baseAddress else {
                preconditionFailure("a non-null span base has an address")
            }
            let address = unsafe Memory.Address(base)
            let length: Memory.Address.Count = buffer.count.retag(Memory.self)

            return try await submit(
                .read(address: address, length: length, offset: nil),
                descriptor: consume descriptor
            ) { event throws(Completion.Failure) in
                if let error = event.result.failure { throw error.completionFailure }
                guard let value = event.result.value else {
                    preconditionFailure("a completion without a failure carries a value")
                }
                return Int(value)
            }
        }

        public func write(
            to fd: borrowing Kernel.Descriptor,
            from buffer: Span.Raw
        ) async throws(Completion.Failure) -> Int {
            let raw = unsafe buffer.base.nonNull

            let descriptor: Kernel.Descriptor?
            do throws(Kernel.Descriptor.Duplicate.Error) {
                descriptor = try Kernel.Descriptor.Duplicate.duplicate(fd)
            } catch {
                throw error.completionFailure
            }

            guard let base = raw.baseAddress else {
                preconditionFailure("a non-null span base has an address")
            }
            let address = unsafe Memory.Address(base)
            let length: Memory.Address.Count = buffer.count.retag(Memory.self)

            return try await submit(
                .write(address: address, length: length, offset: nil),
                descriptor: consume descriptor
            ) { event throws(Completion.Failure) in
                if let error = event.result.failure { throw error.completionFailure }
                guard let value = event.result.value else {
                    preconditionFailure("a completion without a failure carries a value")
                }
                return Int(value)
            }
        }

        public func close(_ fd: consuming Kernel.Descriptor) async {
            do throws(Kernel.Close.Error) {
                try Kernel.Close.close(consume fd)
            } catch {

            }
        }

        public func ready(
            from fd: borrowing Kernel.Descriptor,
            interest: Kernel.Event.Interest
        ) async throws(Completion.Failure) {
            let descriptor: Kernel.Descriptor?
            do throws(Kernel.Descriptor.Duplicate.Error) {
                descriptor = try Kernel.Descriptor.Duplicate.duplicate(fd)
            } catch {
                throw error.completionFailure
            }

            _ = try await submit(
                .readiness(events: interest),
                descriptor: consume descriptor
            ) { event throws(Completion.Failure) in
                if let error = event.result.failure { throw error.completionFailure }
            }
        }
    }

#endif
