# FFmpeg patches

Apply `ffmpeg-runtime.patch` first for repeated execution and command-state reset.
Then apply the target's patches:

- Mobile: `mobile.patch` adds sessions, cancellation, captured logs and progress polling.
- Wasm: `wasm.patch` adds browser progress, timeouts and reusable ffprobe;
  `wasm-fibers.patch` adds cooperative scheduling.
- Desktop: no FFmpeg patches. The x264 cleanup patch is shared by all targets;
  the dav1d patch is Wasm-only.

Mobile runs one command at a time. Each session runs once; free it only after
execution returns and progress polling stops. Cancellation returns `255`.
Copy the bounded error output before freeing the session.

After shared changes, run the state audit, native harness and browser tests.
The audit checks reset assignments; review upstream defaults when upgrading.
