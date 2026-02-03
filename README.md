# sbox-public-linux-docker

## Prerequisites

- **Docker** or **Podman**
- Local clone of [sbox-public](https://github.com/Facepunch/sbox-public)
- Docker permissions: `sudo usermod -aG docker $USER` then run 'newgrp docker' or log out and back in

## Quick Start

```bash
# Clone this repo and the sbox-public repo
git clone https://github.com/tsktp/sbox-public-linux-docker.git
git clone https://github.com/Facepunch/sbox-public.git

# Compile your local sbox-public source
cd sbox-public-linux-docker
./sbox-install.sh compile ~/Documents/sbox-public

# Or compile current directory
./sbox-install.sh compile .
```

## How It Works

1. **Builds a container** with Wine + Windows .NET 10 SDK (one time setup)
2. **Mounts your local sbox-public** directory into the container
3. **Compiles using the container's** Windows environment
4. **Outputs go back to your directory** just like on Windows

## Commands

```bash
./sbox-install.sh compile [dir]    # Compile your local sbox source
./sbox-install.sh shell [dir]      # Open shell in build environment
./sbox-install.sh help             # Show help
```

## Why Docker?

s&box build tools are Windows applications requiring:
- Windows .NET 10 SDK (not Linux version)
- Wine with specific Windows components
- Registry, DLLs, and winetricks packages

Docker isolates this Windows emulation mess so it doesn't pollute your system. The alternative is configuring Wine manually (which often fails with cryptic errors).
