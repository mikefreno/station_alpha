#!/usr/bin/env bash

current_dir=$(basename "$PWD")

libs_dir="game/libs"

if [[ "$current_dir" == "tools" ]]; then
    libs_dir="../${libs_dir}"
fi

mkdir -p "$libs_dir"

cd "$libs_dir" || { echo "❌  Could not cd to $libs_dir"; exit 1; }

if [ -d "Slab/.git" ]; then
    echo "✅  Slab is already present at $(pwd)/Slab"
    exit 0
fi

git clone https://github.com/flamendless/Slab.git

curl -L https://github.com/tesselode/cartographer/blob/master/cartographer.lua -o cartographer.lua


# Optional: check the result
if [ $? -eq 0 ]; then
    echo "🎉  Successfully installed libs"
else
    echo "❌ Lib install failure"
fi

