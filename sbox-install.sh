#!/bin/bash

# sbox-tool: Bootstrap-style compiler for s&box on Linux
# Usage: ./sbox-install.sh [compile|shell] [directory]
# Compiles your local sbox-public source, just like Bootstrap.bat on Windows

set -e

IMAGE_NAME="sbox-public-builder"

show_help() {
    echo "sbox-tool - s&box Linux Bootstrap Compiler"
    echo ""
    echo "Usage:"
    echo "  $0 compile [dir]   Compile s&box from your local source"
    echo "  $0 shell [dir]     Open a shell in the build environment"
    echo ""
    echo "Examples:"
    echo "  $0 compile ~/Documents/sbox-public"
    echo "  $0 compile .       # Compile current directory"
    echo "  $0 compile         # Uses current directory"
}

detect_engine() {
    if command -v docker >/dev/null 2>&1; then
        echo "docker"
    elif command -v podman >/dev/null 2>&1; then
        echo "podman"
    else
        echo ""
    fi
}

ENGINE=$(detect_engine)
if [ -z "$ENGINE" ]; then
    echo "Error: Neither docker nor podman found."
    exit 1
fi

COMMAND=$1
BUILD_DIR="${2:-$(pwd)}"

# Resolve full path
if [[ "$BUILD_DIR" == ~* ]]; then
    BUILD_DIR="${BUILD_DIR/\~/$HOME}"
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Directory does not exist: $BUILD_DIR"
    exit 1
fi

BUILD_DIR=$(cd "$BUILD_DIR" && pwd)

case "$COMMAND" in
    compile)
        echo "========================================"
        echo "s&box Linux Bootstrap Compiler"
        echo "========================================"
        echo ""
        echo "Source: $BUILD_DIR"
        echo ""
        
        # Build image if needed
        if ! $ENGINE image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
            echo "Setting up build environment (first time)..."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            $ENGINE build -t "$IMAGE_NAME" "$SCRIPT_DIR" 2>&1 | tail -5
            echo ""
        fi
        
        echo "Step 1/3: Building engine (this may take 5-10 minutes)..."
        $ENGINE run --rm -t -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" \
            /bin/bash -c "cd /root/sbox && xvfb-run -a -s '-screen 0 1024x768x24' wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build --config Developer 2>&1"
        
        echo ""
        echo "Step 2/3: Building shaders..."
        $ENGINE run --rm -t -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" \
            /bin/bash -c "cd /root/sbox && xvfb-run -a -s '-screen 0 1024x768x24' wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build-shaders 2>&1"
        
        echo ""
        echo "Step 3/3: Building content..."
        $ENGINE run --rm -t -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" \
            /bin/bash -c "cd /root/sbox && xvfb-run -a -s '-screen 0 1024x768x24' wine dotnet run --project ./engine/Tools/SboxBuild/SboxBuild.csproj -- build-content 2>&1"
        
        # Fix file permissions (Docker creates files as root)
        echo ""
        echo "Fixing file permissions..."
        $ENGINE run --rm -v "$BUILD_DIR:/root/sbox" "$IMAGE_NAME" chown -R $(id -u):$(id -g) /root/sbox
        
        echo ""
        echo "========================================"
        echo "Build complete!"
        echo "Output: $BUILD_DIR/game/"
        echo "========================================"
        ;;
        
    shell)
        echo "Opening build shell..."
        echo "Directory: $BUILD_DIR"
        echo ""
        
        if ! $ENGINE image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            $ENGINE build -t "$IMAGE_NAME" "$SCRIPT_DIR" 2>&1 | tail -5
            echo ""
        fi
        
        $ENGINE run -it --rm -v "$BUILD_DIR:/root/sbox" -e WINEDEBUG=-all "$IMAGE_NAME" /bin/bash
        
        # Fix permissions after exiting shell
        echo ""
        echo "Fixing file permissions..."
        $ENGINE run --rm -v "$BUILD_DIR:/root/sbox" "$IMAGE_NAME" chown -R $(id -u):$(id -g) /root/sbox
        ;;
        
    help|*)
        show_help
        ;;
esac
