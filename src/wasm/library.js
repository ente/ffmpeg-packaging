// Fibers run sequentially; keep codec/filter auto-threading at one thread.
addToLibrary({
  emscripten_num_logical_cores: () => 1,
  ffmpeg_wasm_progress: (progress, time) =>
    Module["progress"]({ progress, time }),
});
