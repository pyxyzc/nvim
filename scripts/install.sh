#!/usr/bin/env bash
set -eo pipefail

# How to use?
# bash install.sh [...] [-m] [...]

for arg in "$@"; do
  [[ "$arg" == "-h" || "$arg" == "--help" ]] && {
    echo "Usage: "
    echo "  $0 [-m]   # -m use mirror websites"
    exit 0
  }
done

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

ARCH="$(uname -m)"
URL=""
DIR=""

case "$ARCH" in
    aarch64|arm64)
        URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-arm64.tar.gz"
        DIR="nvim-linux-arm64"
        ;;
    x86_64)
        URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
        DIR="nvim-linux-x86_64"
        ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

echo "Downloading Neovim nightly for $ARCH ..."
curl -LO "$URL"

echo "Extracting ..."
tar -zxvf "$DIR.tar.gz"                                                                                                                                                                                   
echo "Installing to /opt/nvim ..."
$SUDO mkdir -p /opt/nvim
$SUDO rsync -a "$DIR"/ /opt/nvim/
$SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

echo "Done!"
nvim --version

echo "=================================================="

mkdir -p ~/.config
[[ -d ~/.config/nvim ]] && rm -rf ~/.config/nvim
[[ -d ~/.local/share/nvim ]] && rm -rf ~/.local/share/nvim

cp -r "$(dirname "$(dirname "$(realpath "$0")")")" ~/.config/nvim

echo "nvim config copied to ~/.config/nvim"

echo "=================================================="

if ! command -v nvm >/dev/null 2>&1; then
  echo ">>> npm not found ..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash -s -- --no-use
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

for arg in "$@"; do
  [[ "$arg" == "-m" ]] && {
    export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
    export NVM_NPM_ORG_MIRROR=https://npmmirror.com/mirrors/npm/
    break
  }
done

echo ">>> Installing the latest Node.js LTS ..."
nvm install --lts
nvm use --lts

echo ">>> Installation complete – versions:"
node --version
npm  --version
