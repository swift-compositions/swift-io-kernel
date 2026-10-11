#if !os(Windows)
    import Kernel

    extension Event.Actor {

        enum RetryDecision: Equatable, Sendable {
            case retry
            case yieldAndRetry
            case halt
        }
    }

    extension Event.Actor.RetryDecision {

        init(for error: Kernel.Event.Driver.Error) {
            switch error {
            case .platform(let code) where code == .EINTR:
                self = .retry

            case .platform(let code) where code == .ENOMEM:
                self = .yieldAndRetry

            case .platform(let code) where code == .EAGAIN:
                self = .retry

            default:
                self = .halt
            }
        }
    }

#endif
