#!/usr/bin/env bash
# Install the MiniTile toolchain on Ubuntu 24.04. Safe to run more than once.
#   - apt:  verilator, iverilog
#   - pip:  verible, pyslang, yowasp-yosys, pytest   (into .venv in the repo root)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APT_PKGS=(verilator iverilog python3-venv)

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

missing=()
for p in "${APT_PKGS[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "[install] apt packages: ${missing[*]}"
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends "${missing[@]}"
else
  echo "[install] apt packages already installed"
fi

if [ ! -x "$ROOT/.venv/bin/python" ]; then
  echo "[install] creating .venv"
  python3 -m venv "$ROOT/.venv"
fi
echo "[install] python packages"
"$ROOT/.venv/bin/pip" install -q --disable-pip-version-check -r "$ROOT/tools/requirements.txt"

echo "[install] done. Run 'make check-tools' to see versions."
