# FFmpeg packaging

Pinned Android/iOS libraries, desktop CLIs, and a browser Wasm core for Ente.
Source and toolchain versions are in [versions.env](versions.env).
Build prerequisites and release steps live in [.github/workflows](.github/workflows).
Outputs default to `../ffmpeg-workspace`; override `FFMPEG_WORKSPACE`.

```sh
scripts/build-mobile.sh android-arm64
scripts/build-mobile.sh android-armv7
scripts/package-android-aar.sh

scripts/build-mobile.sh ios-device-arm64
scripts/build-mobile.sh ios-sim-arm64
scripts/package-ios-xcframework.sh

scripts/build-desktop-cli.sh desktop-darwin-universal # --help lists targets
scripts/build-wasm.sh # activate the pinned Emscripten SDK first
```

Release builds verify every desktop architecture and publish native and Wasm
archives with checksums. The Wasm workflow can also run on its own. Native runtime tests are in
`tests/runtime`; browser checks are in `tests/wasm`.

[Runtime contracts](docs/mobile-fftools-patch.md) · [Dependencies and patches](docs/dependency-review.md)
