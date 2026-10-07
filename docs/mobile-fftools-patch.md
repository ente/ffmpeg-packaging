# Embedded runtime contracts

`patches/ffmpeg-9.0/ffmpeg-runtime.patch` makes the CLI command boundary reusable
for mobile and Wasm. Desktop applies neither FFmpeg patch.

- One command runs per process; overlapping native execution returns `EBUSY`.
  Dart isolates share that process and cannot provide independent FFmpeg state.
- A session runs once. Cancellation is cooperative, returns `255`, and survives
  cancellation before execution. Free the session only after execution returns;
  no progress callbacks occur after that return.
- Embedded mobile execution preserves host signal and terminal state. Each run
  resets command options, including overwrite flags and progress timing.
- Warnings/errors use a bounded 8191-byte native tail. Copy it before freeing the
  session; truncation can split UTF-8. Concurrent probes may contribute warnings.
- Mobile probing uses `src/ffmpeg_runtime_probe.c`, not the ffprobe CLI.
  `-report`, `FFREPORT`, and CLI help/version commands are outside the mobile API.
- Wasm additionally applies `wasm.patch` for ffprobe cleanup, timeouts and progress.
  A thrown runtime error retires the worker; ordinary nonzero results can reuse it.

`scripts/validate-fftools-state-audit.sh` owns the state inventory. On FFmpeg
upgrades, review changed initializer values too: the audit checks assignments,
not equivalence to upstream defaults. Shared patch changes need both the native
harness and browser tests. Native harness usage:

```sh
tests/runtime/run-mobile-harness.sh --android-device <adb-id>
tests/runtime/run-mobile-harness.sh --ios-simulator <simulator-udid>
```

The iOS harness covers the simulator; physical-device validation uses the app.
