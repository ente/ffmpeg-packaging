#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/verify-desktop-cli.sh <artifact-dir>

Verifies an unpacked desktop artifact directory containing ffmpeg and ffprobe.
USAGE
}

if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi
[ "$#" -eq 1 ] || { usage; exit 2; }
artifact_dir="$1"

require_dir "$artifact_dir"
require_cmd python3
require_cmd rg
ensure_common_dirs
ffmpeg="$artifact_dir/ffmpeg"
ffprobe="$artifact_dir/ffprobe"
if [ ! -x "$ffmpeg" ] && [ -x "$artifact_dir/ffmpeg.exe" ]; then
  ffmpeg="$artifact_dir/ffmpeg.exe"
fi
if [ ! -x "$ffprobe" ] && [ -x "$artifact_dir/ffprobe.exe" ]; then
  ffprobe="$artifact_dir/ffprobe.exe"
fi
require_executable "$ffmpeg"
require_executable "$ffprobe"

if [ "$(uname -s)" = "Darwin" ]; then
  for binary in "$ffmpeg" "$ffprobe"; do
    load_commands="$WORK_ROOT/$(basename "$binary")-load-commands.txt"
    otool -l "$binary" > "$load_commands"
    python3 - "$binary" "$load_commands" "$DESKTOP_MACOS_MIN_VERSION" <<'PY'
import re
import sys

binary, report, maximum = sys.argv[1:]
with open(report, encoding="utf-8") as handle:
    versions = re.findall(r"^\s+minos ([0-9.]+)$", handle.read(), re.M)
def numeric_version(value):
    return tuple(map(int, (value.split(".") + ["0", "0"])[:3]))
if not versions or any(numeric_version(v) > numeric_version(maximum) for v in versions):
    raise SystemExit(f"{binary} has macOS minimum versions {versions}; max allowed is {maximum}")
PY
  done
fi

if command -v ldd >/dev/null 2>&1 && [ "$(uname -s)" = "Linux" ]; then
  ldd "$ffmpeg" > "$WORK_ROOT/desktop-ffmpeg-ldd.txt"
  if rg -q 'lib(x264|zimg|dav1d)' "$WORK_ROOT/desktop-ffmpeg-ldd.txt"; then
    die "desktop ffmpeg must link pinned x264/zimg/dav1d statically"
  fi
fi

if [ "$(uname -s)" = "Linux" ]; then
  require_cmd readelf
  for binary in "$ffmpeg" "$ffprobe"; do
    report="$WORK_ROOT/$(basename "$binary")-elf.txt"
    LC_ALL=C readelf --wide --version-info "$binary" > "$report"
    python3 - "$binary" "$report" "$DESKTOP_LINUX_MAX_GLIBC" \
      "$DESKTOP_LINUX_MAX_GLIBCXX" "$DESKTOP_LINUX_MAX_CXXABI" <<'PYTHON'
import re
import sys
from pathlib import Path

binary, report, *limits = sys.argv[1:]
text = Path(report).read_text(encoding="utf-8")

def numeric(value):
    return tuple(map(int, value.split(".")))

for namespace, limit in zip(("GLIBC", "GLIBCXX", "CXXABI"), limits):
    versions = re.findall(rf"\b{namespace}_([0-9.]+)", text)
    if not versions or max(map(numeric, versions)) > numeric(limit):
        raise SystemExit(f"{binary}: missing or unsupported {namespace} versions; maximum is {limit}")
PYTHON
  done
fi

python3 "$REPO_ROOT/tests/desktop_cli/verify_media.py" \
  --ffmpeg "$ffmpeg" \
  --ffprobe "$ffprobe" \
  --work-dir "$WORK_ROOT" \
  --target "$(basename "$artifact_dir")"

log "desktop CLI verification complete for $artifact_dir"
