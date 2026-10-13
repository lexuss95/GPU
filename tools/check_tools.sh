#!/usr/bin/env bash
# Print the version of every tool and fail if one is missing.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$ROOT/.venv/bin:$PATH"
fail=0

show() {  # name, version command
  local name="$1"; shift
  if out="$("$@" 2>&1 | head -1)" && [ -n "$out" ]; then
    printf "  %-24s %s\n" "$name" "$out"
  else
    printf "  %-24s MISSING (run tools/install.sh)\n" "$name"; fail=1
  fi
}

echo "MiniTile toolchain:"
show verilator              verilator --version
show iverilog               vvp -V
show yosys (yowasp)         yowasp-yosys -V
show verible                python -c "from importlib.metadata import version; print('verible', version('verible'))"
show verible-verilog-lint   verible-verilog-lint --version
show verible-verilog-format verible-verilog-format --version
show pyslang                python -c "import pyslang; print('pyslang', pyslang.VersionInfo.getMajor(), pyslang.VersionInfo.getMinor())"
show pytest                 python -m pytest --version

# Verilator 5 is required (timing support for testbenches).
if command -v verilator >/dev/null && ! verilator --version | grep -q "^Verilator 5\."; then
  echo "  verilator: version 5.x required"; fail=1
fi
exit $fail
