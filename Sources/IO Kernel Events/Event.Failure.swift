#if !os(Windows)
    public import Either
    public import Async_Lifecycle

    extension Event {

        public typealias Failure = Either<Async.Lifecycle.Error, Event.Error>
    }

#endif
