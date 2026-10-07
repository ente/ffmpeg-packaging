# Dependencies and patches

[versions.env](../versions.env) pins FFmpeg, x264, zimg, dav1d and toolchains to
upstream sources. These builds enable GPL components, including x264; see
[FFmpeg's licensing information](https://ffmpeg.org/legal.html).

`patches/x264/encoder-open-cleanup.patch` frees copied parameter strings after
encoder initialization fails. It follows the successful close path's ownership
rules. [Upstream MR 183](https://code.videolan.org/videolan/x264/-/merge_requests/183)
was closed without merging; this remains a local patch, not an upstream fix.

Advisory/source checks were performed on 2026-10-05–06, not a complete audit:

- The pinned dav1d is newer than the affected versions in CVE-2023-32570 and
  CVE-2024-1580. librist is disabled. CVE-2025-25467 has no OSV commit mapping;
  the x264 patch above addresses the inspected allocation ownership issue.
- Wasm's Emscripten zlib port pins 1.3.2; the APIs described by CVE-2026-85091
  are not referenced by FFmpeg. The browser test wrapper is Ente's existing
  `@ffmpeg/ffmpeg` 0.12.15; install test dependencies with `--ignore-scripts`.

Recheck exact versions and upstream build scripts when changing dependencies.
