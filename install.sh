#!/usr/bin/env bash
# Vorlang Installer v0.10-super
# Date: December 27, 2025
# Support: Linux, macOS, WSL

set -e

# --- Configuration ---
VERSION="v0.10-super"
REPO_URL="https://github.com/EmekaIwuagwu/vorlang"
INSTALL_PREFIX="/usr/local"
SHARE_DIR="$INSTALL_PREFIX/share/vorlang"
BIN_DIR="$INSTALL_PREFIX/bin"
LOG_FILE="/tmp/vorlang_install.log"

# --- UI Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# --- Platform Detection ---
detect_os() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    case "$OS" in
        Linux*)  PLATFORM="linux" ;;
        Darwin*) PLATFORM="macos" ;;
        *)       error "Unsupported OS: $OS" ;;
    esac
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        log "WSL detected."
    fi
}

# --- Dependency Management ---
check_deps() {
    log "Checking dependencies..."
    DEPS=("make" "git" "openssl" "ocaml" "ocamlbuild")
    MISSING=()
    for dep in "${DEPS[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            MISSING+=("$dep")
        fi
    done

    if [ ${#MISSING[@]} -ne 0 ]; then
        warn "Missing dependencies: ${MISSING[*]}"
        read -p "Would you like to auto-install these? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_deps_auto
        else
            error "Please install missing dependencies and try again."
        fi
    fi
}

install_deps_auto() {
    if [ "$PLATFORM" == "macos" ]; then
        if ! command -v brew &> /dev/null; then
            error "Homebrew not found. Install it first: https://brew.sh"
        fi
        brew install make openssl ocaml opam
    elif [ "$PLATFORM" == "linux" ]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y make git libssl-dev ocaml-interp ocamlbuild
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y make git openssl-devel ocaml ocaml-ocamlbuild
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm make git openssl ocaml ocamlbuild
        else
            error "Unsupported Linux distro. Install make, openssl, and ocaml manually."
        fi
    fi
}

# --- Installation ---
install_vorlang() {
    log "Downloading Vorlang $VERSION..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Check if we are running from within the git repo already
    if [ -f "$(dirname "$0")/Makefile" ] && [ -d "$(dirname "$0")/src" ]; then
        log "Installing from local source..."
        cd "$(dirname "$0")"
    else
        log "Cloning repository..."
        git clone --depth 1 "$REPO_URL" .
    fi

    log "Building compiler (make)..."
    make clean > /dev/null 2>&1 || true
    make > "$LOG_FILE" 2>&1

    if [ ! -f "./vorlangc" ]; then
        error "Build failed. See $LOG_FILE for details."
    fi

    log "Installing files to $INSTALL_PREFIX..."
    sudo mkdir -p "$BIN_DIR" "$SHARE_DIR"
    sudo cp -r stdlib examples "$SHARE_DIR/"
    sudo cp vorlangc "$BIN_DIR/vorlangc"
    sudo chmod +x "$BIN_DIR/vorlangc"

    # Create 'vorlang' symlink for REPL
    echo -e "#!/usr/bin/env bash\nexport VORLANG_STDLIB=$SHARE_DIR/stdlib\n$BIN_DIR/vorlangc repl \"\$@\"" | sudo tee "$BIN_DIR/vorlang" > /dev/null
    sudo chmod +x "$BIN_DIR/vorlang"

    log "Verifying installation..."
    if "$BIN_DIR/vorlangc" run "$SHARE_DIR/examples/test_simple.vorlang" | grep -q "PASS"; then
        success "Vorlang $VERSION installed successfully!"
    else
        warn "Installation complete, but smoke test failed. Check $LOG_FILE."
    fi
}

# --- Main ---
detect_os
check_deps
install_vorlang

success "You can now use 'vorlangc' to compile and 'vorlang' to launch the REPL."
log "Try: vorlangc run $SHARE_DIR/examples/test_storage_security.vorlang"
