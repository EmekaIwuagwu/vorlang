#!/usr/bin/env bash
# Vorlang Production Installer v0.10-super
# Date: December 26, 2025

set -e

# --- Configuration ---
REPO_URL="https://github.com/EmekaIwuagwu/vorlang"
INSTALL_PREFIX="/usr/local"
BIN_DIR="$INSTALL_PREFIX/bin"
LOG_FILE="/tmp/vorlang_install.log"

# --- UI Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { 
    echo -e "${RED}[ERROR]${NC} $1"
    if [ -f "$LOG_FILE" ]; then
        echo -e "${RED}Last 15 lines of build log ($LOG_FILE):${NC}"
        tail -n 15 "$LOG_FILE"
    fi
    exit 1; 
}

# 1. Dependency Validation & Auto-Installation
log "Validating environment and dependencies..."
OS="$(uname -s)"

if [ "$OS" == "Linux" ]; then
    if command -v apt-get &> /dev/null; then
        log "Updating package list..."
        sudo apt-get update -qq
        log "Installing OCaml build tools and OpenSSL..."
        sudo apt-get install -y -qq make git ocaml ocaml-interp ocamlbuild libssl-dev menhir > /dev/null
    fi
elif [ "$OS" == "Darwin" ]; then
    if command -v brew &> /dev/null; then
        log "Installing dependencies via Homebrew..."
        brew install make ocaml ocamlbuild openssl menhir
    fi
fi

# 2. Clone Repository
log "Fetching latest Vorlang source..."
TMP_DIR=$(mktemp -d)
if ! git clone --depth 1 "$REPO_URL" "$TMP_DIR" > /dev/null 2>&1; then
    error "Failed to clone repository from $REPO_URL"
fi
cd "$TMP_DIR"

# 3. Build Compiler
log "Building Vorlang compiler (running make)..."
# We check if Makefile exists
if [ ! -f "Makefile" ]; then
    error "Makefile not found in repository root."
fi

if ! make > "$LOG_FILE" 2>&1; then
    error "Compilation failed. Ensure OCaml and its build tools are correctly installed."
fi

# 4. System Installation
log "Installing binaries and standard library to $INSTALL_PREFIX..."
# We assume the Makefile has an 'install' target. 
# If it doesn't, we will manually install as a fallback.
if grep -q "install:" Makefile; then
    sudo make install PREFIX="$INSTALL_PREFIX" > /dev/null
else
    warn "Makefile is missing an 'install' target. Performing manual installation..."
    sudo mkdir -p "$BIN_DIR"
    sudo mkdir -p "$INSTALL_PREFIX/share/vorlang"
    sudo cp vorlangc "$BIN_DIR/vorlangc"
    sudo chmod +x "$BIN_DIR/vorlangc"
    sudo cp -r stdlib "$INSTALL_PREFIX/share/vorlang/"
    
    # Create REPL wrapper
    echo -e "#!/bin/sh\nexport VORLANG_STDLIB=$INSTALL_PREFIX/share/vorlang/stdlib\n$BIN_DIR/vorlangc repl \"\$@\"" | sudo tee "$BIN_DIR/vorlang" > /dev/null
    sudo chmod +x "$BIN_DIR/vorlang"
fi

# 5. Verification & Smoke Test
if command -v vorlangc &> /dev/null; then
    log "Running smoke test..."
    if vorlangc run examples/test_simple.vorlang | grep -q "PASS"; then
        echo -e "${GREEN}✅ Vorlang v0.10-super has been successfully installed!${NC}"
        echo -e "Available commands:"
        echo -e "  - ${BLUE}vorlangc${NC} (Compiler & Runtime)"
        echo -e "  - ${BLUE}vorlang${NC}  (Interactive REPL)"
        echo -e "\nTry running: ${BLUE}vorlangc run examples/test_storage_security.vorlang${NC}"
    else
        warn "Installation finished, but smoke test failed. Please check the logs."
    fi
else
    error "Installation failed: 'vorlangc' not found in PATH."
fi

# Cleanup
rm -rf "$TMP_DIR"
