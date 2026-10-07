Module["ret"] = -1;
Module["logger"] = () => {};
Module["progress"] = () => {};
Module["print"] = (message) => Module["logger"]({ type: "stdout", message });
Module["printErr"] = (message) => Module["logger"]({ type: "stderr", message });
Module["setLogger"] = (logger) => (Module["logger"] = logger);
Module["setProgress"] = (progress) => (Module["progress"] = progress);
Module["setTimeout"] = (timeout) => Module["_ffmpeg_wasm_set_timeout"](timeout);
Module["reset"] = () => {
  Module["ret"] = -1;
};
let poisoned = false;
function runFFmpeg(probe, args) {
  if (poisoned)
    throw new Error("FFmpeg runtime failed; terminate and reload the worker");
  const pointers = [];
  let argv = 0;
  try {
    for (const value of args) {
      const size = Module["lengthBytesUTF8"](value) + 1;
      const ptr = Module["_malloc"](size);
      if (!ptr) throw new Error("FFmpeg argument allocation failed");
      pointers.push(ptr);
      Module["stringToUTF8"](value, ptr, size);
    }
    argv = Module["_malloc"]((pointers.length + 1) * 4);
    if (!argv) throw new Error("FFmpeg argument allocation failed");
    pointers.forEach((ptr, i) => Module["setValue"](argv + i * 4, ptr, "i32"));
    Module["setValue"](argv + pointers.length * 4, 0, "i32");
    Module["_ffmpeg_wasm_run"](probe, args.length, argv);
  } catch (error) {
    poisoned = true;
    throw error;
  } finally {
    // A trap can leave C state inconsistent. Only a new worker may use it again.
    if (!poisoned) {
      pointers.forEach((ptr) => Module["_free"](ptr));
      Module["_free"](argv);
    }
  }
  return Module["ret"];
}
Module["exec"] = (...args) =>
  runFFmpeg(0, [
    "./ffmpeg",
    "-nostdin",
    "-y",
    ...args,
  ]);
Module["ffprobe"] = (...args) =>
  runFFmpeg(1, ["./ffprobe", ...args]);
{
  const scriptURL = Module["mainScriptUrlOrBlob"];
  if (typeof scriptURL !== "string" || !scriptURL.includes("#"))
    throw new Error("Load this core through @ffmpeg/ffmpeg");
  const separator = scriptURL.lastIndexOf("#");
  const { wasmURL } = JSON.parse(atob(scriptURL.slice(separator + 1)));
  Module["locateFile"] = (path, prefix) =>
    path.endsWith(".wasm") ? wasmURL : prefix + path;
}
