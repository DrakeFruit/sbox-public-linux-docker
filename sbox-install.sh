#!/bin/bash

# sbox-tool: Bootstrap-style compiler for s&box on Linux
set -e

IMAGE_NAME="sbox-public-builder"

show_help() {
    echo "sbox-tool - s&box Linux Bootstrap Compiler"
    echo ""
    echo "Usage:"
    echo "  $0 [command] [dir]"
    echo ""
    echo "Commands:"
    echo "  compile    Full build (engine -> shaders -> content)"
    echo "  engine     Compile only the engine"
    echo "  shaders    Compile only the shaders"
    echo "  content    Compile only the content"
    echo "  shell      Open a shell in the build environment"
    echo ""
    echo "Examples:"
    echo "  $0 compile ~/sbox-public"
    echo "  $0 engine ."
}

detect_engine() {
    if command -v docker >/dev/null 2>&1; then echo "docker";
    elif command -v podman >/dev/null 2>&1; then echo "podman";
    fi
}

# --- Initialization ---
ENGINE=$(detect_engine)
if [ -z "$ENGINE" ]; then echo "Error: No container engine found."; exit 1; fi

COMMAND=$1
# Dir is 2nd arg; if empty, use current directory
BUILD_DIR="${2:-$(pwd)}"

# Resolve paths and tilde expansion
if [[ "$BUILD_DIR" == ~* ]]; then BUILD_DIR="${BUILD_DIR/\~/$HOME}"; fi
if [ ! -d "$BUILD_DIR" ]; then echo "Error: Directory not found: $BUILD_DIR"; exit 1; fi
BUILD_DIR=$(cd "$BUILD_DIR" && pwd)

# Ensure Image Exists
if ! $ENGINE image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Setting up build environment..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    $ENGINE build -t "$IMAGE_NAME" "$SCRIPT_DIR"
fi

# Function to run the build tool inside the container
run_build() {
    local task=$1
    local task_label=$2
    echo "----------------------------------------"
    echo "==> $task_label"
    echo "----------------------------------------"
    $ENGINE run --rm -t -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" \
        /bin/bash -c "cd /root/sbox && xvfb-run -a -s '-screen 0 1024x768x24' wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- $task --config Developer 2>&1"
}

fix_perms() {
    echo ""
    echo "Fixing file permissions..."
    $ENGINE run --rm -v "$BUILD_DIR:/root/sbox" "$IMAGE_NAME" chown -R $(id -u):$(id -g) /root/sbox
}

# --- Execution Logic ---
case "$COMMAND" in
    compile|all)
        echo "Starting Full Build for: $BUILD_DIR"
        run_build "build" "Step 1/3: Engine"
        run_build "build-shaders" "Step 2/3: Shaders"
        run_build "build-content" "Step 3/3: Content"
        fix_perms
        echo "========================================"
        echo "Full build complete!"
        ;;
    engine)
        run_build "build" "Engine Build"
        fix_perms
        ;;
    shaders)
        run_build "build-shaders" "Shader Build"
        fix_perms
        ;;
    content)
        run_build "build-content" "Content Build"
        fix_perms
        ;;
    shell)
        echo "Opening build shell in: $BUILD_DIR"
        $ENGINE run -it --rm -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" /bin/bash
        fix_perms
        ;;
    help|*)
        show_help
        ;;
esac
