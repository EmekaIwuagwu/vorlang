#!/usr/bin/env bash
# Vorlang Production Installer v0.10-super
# Date: December 26, 2025

set -e

REPO_URL="https://github.com/EmekaIwuagwu/vorlang"
PREFIX="/usr/local"
BIN_DIR="$PREFIX/bin"

# UI Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect sudo
SUDO=""
if command -v sudo &>/dev/null; then SUDO="sudo"; fi

# 1. Dependency Check
log "Validating dependencies..."
if [[ "$(uname -s)" == "Linux" ]]; then
    if command -v apt-get &>/dev/null; then
        log "Installing OCaml toolchain and OpenSSL via apt..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y make git ocaml ocaml-findlib ocamlbuild libssl-dev menhir libmenhir-ocaml-dev > /dev/null
    fi
fi

# 2. Clone Repository
log "Cloning Vorlang source..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 "$REPO_URL" "$TMP_DIR" > /dev/null 2>&1 || error "Git clone failed."
cd "$TMP_DIR"

# 3. Build Compiler
log "Building compiler (running make)..."
# We DO NOT suppress output here so we can see any errors
make || error "Compilation failed. See output above."

# 4. Installation
if command -v vorlangc &>/dev/null || [ -f "./vorlangc" ]; then
    log "Installing to $PREFIX..."
    $SUDO make install PREFIX="$PREFIX" || {
        log "Makefile install failed, performing manual install..."
        $SUDO mkdir -p "$BIN_DIR"
        $SUDO mkdir -p "$PREFIX/share/vorlang"
        $SUDO cp vorlangc "$BIN_DIR/vorlangc"
        $SUDO chmod +x "$BIN_DIR/vorlangc"
        $SUDO cp -r stdlib "$PREFIX/share/vorlang/"
        # Create REPL wrapper
        echo -e "#!/bin/sh\nexport VORLANG_STDLIB=$PREFIX/share/vorlang/stdlib\n$BIN_DIR/vorlangc repl \"\$@\"" | $SUDO tee "$BIN_DIR/vorlang" > /dev/null
        $SUDO chmod +x "$BIN_DIR/vorlang"
    }
else
    error "Compilation finished but 'vorlangc' binary was not found."
fi

# 5. Verification
if command -v vorlangc &>/dev/null; then
    echo -e "${GREEN}✅ Vorlang installed successfully!${NC}"
    echo -e "Try: ${BLUE}vorlangc --version${NC}"
else
    echo -e "${RED}❌ Installation appeared successful but 'vorlangc' is not in your PATH.${NC}"
fi

rm -rf "$TMP_DIR"