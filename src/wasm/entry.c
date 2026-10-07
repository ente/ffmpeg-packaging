#include <emscripten.h>

int ffmpeg_wasm_main(int argc, char **argv);
int ffprobe_wasm_main(int argc, char **argv);

void ffmpeg_wasm_run(int probe, int argc, char **argv)
{
    int ret = probe ? ffprobe_wasm_main(argc, argv) : ffmpeg_wasm_main(argc, argv);
    // Fiber rewinding discards the original JS call's return value.
    EM_ASM({ Module["ret"] = $0; }, ret);
}
