# swift-io-kernel

Use this package to drive file-descriptor I/O asynchronously from the kernel's own event mechanism on every platform except Windows. Start from `Kernel.Event.Actor` when you want readiness (the kernel says a descriptor can be read or written and you make the syscall yourself), or from `Kernel.Completion.Actor` when you want completion (the kernel performs the operation and reports its result). The `IO` witness itself comes from swift-io and the syscalls from swift-kernel; this package only connects the two. `IO Kernel Test Support` builds byte-level `IO` witnesses on both actors and on a blocking thread, and `IO Kernel Completions Test Support` adds `Kernel.Completion.Fake`, which scripts the completions a submission receives.

## Laws

- Each actor's executor is the thread that polls the kernel. Isolated work on the actor, and on any actor or `IO` witness that adopts its `unownedExecutor`, runs on that thread without a hop, and holds up polling while it runs.
- `shared()` creates one actor per process on first use and caches the outcome: if that first creation failed, every later call throws the same error.
- Releasing either actor shuts its thread and its kernel source down.
- `Kernel.Event.Actor.register(_:)` duplicates the descriptor and registers the copy for both read and write. Registering a descriptor with the same number again returns the first ID until it is deregistered.
- `Kernel.Event.Actor.deregister(_:)` takes the ID derived from the descriptor (`Kernel.Event.ID(descriptor:)`), not the ID `register(_:)` returned. An unknown ID is ignored.
- `Kernel.Event.Actor.wait(for:interest:)` arms the interest and resumes on the next matching event. Each event resumes every waiter filed under that interest and then forgets them, so a waiter that wants the next event waits again. A wait whose interest contains read is filed under read even if it also contains write; one with neither is filed under priority.
- Cancelling a `Kernel.Event.Actor` wait fails it with `.left(.cancelled)` and removes only that waiter; other waiters on the same interest keep waiting. If arming fails, the waiter is removed before the error is thrown.
- `Kernel.Event.Actor.shutdown()` and `deregister(_:)` end every pending wait on the affected registrations with `.left(.shutdown)`. After shutdown, `register(_:)` and `wait(for:interest:)` fail with `.left(.shutdown)`. `shutdown()` may be called any number of times.
- A `Kernel.Event.Actor` poll error of `EINTR` or `EAGAIN` retries, `ENOMEM` yields the thread and then retries, and any other error shuts the actor down as `shutdown()` does.
- A duplication failure in `Kernel.Event.Actor.register(_:)` becomes `invalidDescriptor` for a bad handle and `platform(.EMFILE)` when the process is out of descriptors. A source that does not support the platform reports `platform(.ENOTSUP)`. `EPIPE` on read or write becomes `readClosed` or `writeClosed`.
- Every `Kernel.Completion.Actor` submission, including the cancel submissions the actor sends itself, gets a fresh token; tokens start at 1 and increase.
- When the task submitting to `Kernel.Completion.Actor` is cancelled, the actor marks the operation cancelled and submits `.cancel(target:)` for it. `submit(_:descriptor:mapEvent:)` returns only after the kernel has answered the cancel. If the operation's own completion arrives after the mark, the call throws `.cancelled`; if it arrived before, its result goes through `mapEvent` as usual.
- If the kernel rejects a `Kernel.Completion.Actor` submission, the call throws `.cancelled`.
- A completion whose token `Kernel.Completion.Actor` does not hold is dropped. A poll error is ignored and polling continues.
- A `Kernel.Completion.Entry` must be resolved exactly once, with `resolve(with:)` or `resolveAsCancelled()`. Dropping it unresolved resumes its waiter with no event and then stops the process with a precondition failure.
- In `IO Kernel Test Support`, `IO.default()` picks completions on Linux when io_uring is supported and the shared completion actor starts, otherwise events when the shared event actor starts, otherwise `IO.blocking()`.
- The `IO Kernel Test Support` witnesses map `EPIPE` and closed read or write sides to `Basic.Error.brokenPipe`, an invalid descriptor to `EBADF`, and a completion kernel error to `EIO`.
- `IO.blocking()` does nothing on `ready`, and none of the witnesses' runners do anything on `shutdown`.
