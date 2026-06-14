#!/usr/bin/env bash
#
# lsm — one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash -s -- --prefix=$HOME/.local/bin
#   curl -fsSL https://raw.githubusercontent.com/gabrielcardoso30/lsm/main/install.sh | bash -s -- --version=v0.1.0
#
# Flags:
#   --prefix=<dir>    install directory (default: /usr/local/bin, with sudo fallback)
#   --version=<tag>   release tag to install (default: latest)
#   --no-sudo         never escalate; fail if write permission is missing

set -eu

REPO="gabrielcardoso30/lsm"
PREFIX=""
VERSION=""
USE_SUDO="auto"

for arg in "$@"; do
  case "$arg" in
    --prefix=*)  PREFIX="${arg#*=}" ;;
    --version=*) VERSION="${arg#*=}" ;;
    --no-sudo)   USE_SUDO="no" ;;
    --help|-h)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$PREFIX" ]]; then
  PREFIX="/usr/local/bin"
fi

if [[ -z "$VERSION" ]]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | awk -F'"' '/"tag_name":/ {print $4; exit}')"
  if [[ -z "$VERSION" ]]; then
    printf 'Could not resolve latest release tag from GitHub API.\n' >&2
    exit 1
  fi
fi

ASSET_URL="https://github.com/${REPO}/releases/download/${VERSION}/lsm"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

printf 'Downloading lsm %s from %s\n' "$VERSION" "$ASSET_URL"
curl -fsSL --retry 3 "$ASSET_URL" -o "$TMP"
chmod 0755 "$TMP"

install_to() {
  local dest="$1/lsm"
  if [[ -w "$1" ]] || mkdir -p "$1" 2>/dev/null && [[ -w "$1" ]]; then
    mv "$TMP" "$dest"
  else
    if [[ "$USE_SUDO" == "no" ]]; then
      printf 'No write permission to %s and --no-sudo set.\n' "$1" >&2
      return 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
      printf 'No write permission to %s and sudo is not available.\n' "$1" >&2
      return 1
    fi
    printf 'Elevating with sudo to install into %s\n' "$1"
    sudo install -m 0755 "$TMP" "$dest"
    rm -f "$TMP"
  fi
  printf 'Installed: %s\n' "$dest"
}

install_to "$PREFIX"

if ! command -v lsm >/dev/null 2>&1; then
  printf '\nlsm is installed but %s is not on your PATH.\n' "$PREFIX" >&2
  printf 'Add it to your shell profile, for example:\n' >&2
  printf '  export PATH="%s:$PATH"\n' "$PREFIX" >&2
fi
