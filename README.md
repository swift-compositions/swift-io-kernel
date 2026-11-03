# swift-io-kernel

Use this package when you need asynchronous file-descriptor I/O driven directly by the kernel, behind an `IO` witness. It has two actors. `Event.Actor` is a readiness reactor: it tells you when a descriptor can be read or written, and you then make the syscall yourself. Pick `Completion.Actor` for completion-based I/O, where the kernel performs the operation and reports the result. Both are unavailable on Windows. The `IO Kernel` module re-exports `IO` and both actor modules.

## Model

- `Event.Actor` (`Event` is `Kernel.Event`) is an actor whose `unownedExecutor` is its own polling thread. `init(maxEventsPerPoll:)` opens the platform event source. `init(source:maxEventsPerPoll:)` takes a `Kernel.Event.Source` you supply, such as a fake. `shared()` returns one process-wide instance.
- `register(_:)` duplicates the descriptor, registers the copy for `[.read, .write]` and returns an `Event.ID`. `wait(for:interest:)` arms that interest and suspends until the next matching event. `deregister(_:)` takes the descriptor-derived ID `Event.ID(descriptor: fd)`, not the ID that `register` returned. `shutdown()` stops the actor.
- `Completion.Actor` (`Completion` is `Kernel.Completion`) is an actor whose `unownedExecutor` is its completion thread. Create it with `init(maxCompletionsPerPoll:)`, `init(kernel:maxCompletionsPerPoll:)` or `shared()`. `submit(_:descriptor:mapEvent:)` sends one `Kernel.Completion.Submission.Opcode`, waits for its `Kernel.Completion.Event`, and returns whatever `mapEvent` makes of it.
- `Completion.Entry` is a `~Copyable` pending submission: you must consume it with `resolve(with:)` or `resolveAsCancelled()`. `Completion.Cancellation` is a `Sendable` atomic flag (`set()`, `isSet`).
- Actors and `IO` witnesses that share one of these executors run without hopping between threads.

## Rules

- Registering the same descriptor number again returns the existing ID until you call `deregister`.
- A `wait` delivers one event. Every waiter on that interest wakes, and each must call `wait` again to see the next event. A `wait` whose interest contains `.read` is filed as a read wait, even if it also contains `.write`.
- Cancelling a `wait` throws `.left(.cancelled)` and removes only that waiter. Other waiters on the same interest keep waiting. If arming fails, `wait` throws `.right(Event.Error)` and removes the waiter.
- `shutdown()` and `deregister` close all pending waiters with `.left(.shutdown)`. Once the actor has shut down, `register` and `wait` also fail with `.left(.shutdown)`. `shutdown()` can be called more than once.
- On a poll error, `EINTR` and `EAGAIN` retry, and `ENOMEM` yields the thread and then retries. Any other error halts the actor exactly like `shutdown()`.
- `submit` hands out tokens that increase from 1. If the task is cancelled, `submit` sets the flag, submits `.cancel(target:)`, and throws `.cancelled` only after the kernel has answered the cancel. A completion that arrives for a cancelled entry is turned into `.cancelled`, and so is a failed kernel submission.
- Releasing a `Completion.Actor` shuts its kernel down. Dropping a `Completion.Entry` that was never resolved is a precondition failure.

## Error Handling

- `Event.Failure` is `Either<Async.Lifecycle.Error, Event.Error>`. On the left side the actor throws only `.shutdown` and `.cancelled`. The right side holds `Event.Error`, with the cases `platform(Error.Code)`, `invalidDescriptor`, `alreadyRegistered`, `notRegistered`, `deregistered`, `readClosed`, `writeClosed` and `notConnected`. A duplication failure in `register` becomes `invalidDescriptor` or `platform(.EMFILE)`. Driver errors map to `platform`, `invalidDescriptor` or `notRegistered`.
- `Completion.Failure` has the cases `cancelled`, `invalidDescriptor`, `tooManyOpen`, `platform(Error.Code)` and `kernel(Kernel.Completion.Error)`. `submit` throws `.cancelled` itself and passes on whatever `mapEvent` throws. `Kernel.Descriptor.Duplicate.Error` and `Error::Error` each provide a `completionFailure` to convert into it.

## Example

```swift
import IO_Kernel

let actor = try Event.Actor()
let pipe = try Kernel.Pipe.pipe()

let id = try await actor.register(pipe.write)
try await actor.wait(for: id, interest: .write)  // an empty pipe is writable

await actor.deregister(Event.ID(descriptor: pipe.write))
await actor.shutdown()
```

## Test Support

`IO Kernel Test Support` adds byte operations on top of the actors. It adds `read`, `write`, `ready` and `close` to both actors. It defines `Basic.Capabilities` with `Basic.Error`, the witnesses `IO.events(on:)`, `IO.completions(on:)` and `IO.blocking(on:)`, and `IO.default()`. On Linux with io_uring, `IO.default()` picks completions, then falls back to events, and then to blocking I/O. It also provides `IO.Runner.unimplemented`. `IO Kernel Completions Test Support` adds `Kernel.Completion.Fake` and `Completion.Actor.fake()`, which script the completions a submission receives.
