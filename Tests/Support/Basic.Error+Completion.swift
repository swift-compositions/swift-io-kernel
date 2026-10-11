#if !os(Windows)

    public import IO_Kernel_Completions

    extension Completion.Failure {

        @usableFromInline
        package var basicError: Basic.Error {
            switch self {
            case .cancelled:
                return .cancelled

            case .invalidDescriptor:
                return .platform(.EBADF)

            case .tooManyOpen:
                return .platform(.EMFILE)

            case .platform(let code):
                if code == Error::Error.Code.EPIPE { return .brokenPipe }
                return .platform(code)

            case .kernel:
                return .platform(.EIO)
            }
        }
    }

#endif
