#!/usr/bin/env bash
set -euo pipefail   # fail fast on errors, unset vars, and pipeline failures


current_dir=$(basename "$PWD")
libs_dir="game/libs"

if [[ "$current_dir" == "tools" ]]; then
  libs_dir="../${libs_dir}"
fi

mkdir -p "$libs_dir"
cd "$libs_dir" || { echo "❌  Could not cd to $libs_dir"; exit 1; }

download_file() {
  url=$1
  dest=$2
  desc=${3:-$dest}

  echo "📥  Downloading $desc …"

  # -L  : follow redirects
  # -f  : fail silently on server errors (non‑200)
  # -sS : silent mode, but show errors
  # -o  : write output to $dest
  if ! curl -LfsS "$url" -o "$dest"; then
    echo "❌  Failed to download $desc (HTTP error or network issue)"
    exit 1
  fi

  # realpath may not exist on all systems – fall back to dest itself
  if command -v realpath >/dev/null 2>&1; then
    abs=$(realpath "$dest")
  else
    abs=$dest
  fi
  echo "✅  $desc written to $abs"
}


download_file "https://raw.githubusercontent.com/tesselode/cartographer/master/cartographer.lua" "Cartographer.lua"
download_file "https://raw.githubusercontent.com/Oval-Tutu/bootstrap-love2d-project/main/game/lib/overlayStats.lua" "OverlayStats.lua"
#shouldn't be necessary (submodule)
#download_file "https://raw.githubusercontent.com/mikefreno/FlexLove/main/FlexLove.lua" "FlexLove.lua"

echo "🎉  All libraries installed successfully"

