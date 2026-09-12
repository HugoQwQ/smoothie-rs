#!/usr/bin/env bash

set -euo pipefail

mkdir -p ./smoothie-rs/bin

echo "Checking required tools..."

command -v 7z
command -v curl
command -v cargo
command -v python3

echo "Setting up VapourSynth..."

# VapourSynth installed by pip.
#
# Find the installed library and SDK/include directories.
VAPOURSYNTH_DIR="$(
    python3 - <<'PY'
import os
import vapoursynth

print(os.path.dirname(vapoursynth.__file__))
PY
)"

echo "VapourSynth directory: $VAPOURSYNTH_DIR"

# Depending on the VapourSynth wheel layout, locate the library.
VAPOURSYNTH_LIB="$(
    find "$VAPOURSYNTH_DIR" \
        -type f \
        \( -name 'libvapoursynth-script.so*' -o -name 'libvapoursynth.so*' \) \
        -print -quit
)"

if [[ -z "$VAPOURSYNTH_LIB" ]]; then
    echo "Could not find VapourSynth shared library"
    exit 1
fi

echo "VapourSynth library: $VAPOURSYNTH_LIB"

VAPOURSYNTH_LIB_DIR="$(dirname "$VAPOURSYNTH_LIB")"

export VAPOURSYNTH_LIB_DIR

echo "VAPOURSYNTH_LIB_DIR=$VAPOURSYNTH_LIB_DIR"

echo "Building smoothie-rs..."

cargo build --release

echo "Copying binary..."

cp ./target/release/smoothie-rs \
   ./smoothie-rs/bin/

chmod +x ./smoothie-rs/bin/smoothie-rs

echo "Preparing scripts..."

if [[ ! -d "./smoothie-rs/bin/scripts" ]]; then
    mkdir -p "./smoothie-rs/bin/scripts"
fi

if [[ -d "./smoothie-rs/bin/Scripts" ]]; then
    mv "./smoothie-rs/bin/Scripts" \
       "./smoothie-rs/bin/scripts"
fi

if [[ -d "./target/scripts" ]]; then
    cp -r ./target/scripts/* \
       ./smoothie-rs/bin/scripts/
fi

echo "Copying runtime files..."

cp ./target/jamba.vpy \
   ./smoothie-rs/

cp ./target/*.ini \
   ./smoothie-rs/

echo "Creating launcher..."

cat > ./smoothie-rs/launch.sh <<'EOF'
#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

exec ./bin/smoothie-rs --tui
EOF

chmod +x ./smoothie-rs/launch.sh

echo "Creating archive..."

tar \
    -czf smoothie-rs-nightly.tar.gz \
    ./smoothie-rs

echo "Done."