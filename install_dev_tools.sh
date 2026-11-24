#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" || ! -r /etc/os-release ]]; then
    echo "This script supports Ubuntu and Debian only." >&2
    exit 1
fi

source /etc/os-release
case "$ID" in
    ubuntu|debian) ;;
    *)
        echo "This script supports Ubuntu and Debian only." >&2
        exit 1
        ;;
esac

SUDO=()
if [[ "$EUID" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Install sudo or run this script as root in your Linux lab." >&2
        exit 1
    fi
    SUDO=(sudo)
fi

APT_UPDATED=false
install_packages() {
    if [[ "$APT_UPDATED" == false ]]; then
        "${SUDO[@]}" apt-get update
        APT_UPDATED=true
    fi
    "${SUDO[@]}" apt-get install -y "$@"
}

python_is_supported() {
    command -v python3 >/dev/null 2>&1 &&
        python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'
}

if python_is_supported; then
    echo "Python 3.9+ is already installed. Skipping."
else
    install_packages python3
    if ! python_is_supported; then
        echo "This OS release does not provide Python 3.9+. Use a newer Ubuntu or Debian release." >&2
        exit 1
    fi
fi

NEED_DOCKER=false
NEED_COMPOSE=false
if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1; then
    echo "Docker CLI is already installed. Skipping."
else
    NEED_DOCKER=true
fi

if docker compose version >/dev/null 2>&1 || docker-compose --version >/dev/null 2>&1; then
    echo "Docker Compose is already installed. Skipping."
else
    NEED_COMPOSE=true
fi

if [[ "$NEED_DOCKER" == true || "$NEED_COMPOSE" == true ]]; then
    # Do not replace an existing distribution-managed Docker installation.
    for package in docker.io docker-compose docker-compose-v2 podman-docker containerd runc; do
        if [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" == "install ok installed" ]]; then
            echo "Conflicting package found: $package. Use a clean Linux lab instead of replacing it." >&2
            exit 1
        fi
    done

    install_packages ca-certificates curl
    "${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
    "${SUDO[@]}" curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
        -o /etc/apt/keyrings/docker.asc
    "${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc

    "${SUDO[@]}" tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: ${UBUNTU_CODENAME:-${VERSION_CODENAME:?OS codename is missing}}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    "${SUDO[@]}" apt-get update

    if [[ "$NEED_DOCKER" == true ]]; then
        install_packages docker-ce docker-ce-cli containerd.io
    fi
    if [[ "$NEED_COMPOSE" == true ]]; then
        install_packages docker-compose-plugin
    fi
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
DJANGO_PYTHON=python3

if python3 -m django --version >/dev/null 2>&1; then
    echo "Django is already installed for python3. Skipping."
elif [[ -x "$VENV_DIR/bin/python" ]] && "$VENV_DIR/bin/python" -m django --version >/dev/null 2>&1; then
    DJANGO_PYTHON="$VENV_DIR/bin/python"
    echo "Django is already installed in .venv. Skipping."
else
    # Keep pip packages separate from the system Python installation.
    if [[ ! -x "$VENV_DIR/bin/python" ]]; then
        install_packages python3-venv
        python3 -m venv "$VENV_DIR"
    fi
    DJANGO_PYTHON="$VENV_DIR/bin/python"
    "$DJANGO_PYTHON" -m pip install Django
fi

docker --version
if docker compose version >/dev/null 2>&1; then
    docker compose version
else
    docker-compose --version
fi
python3 --version
"$DJANGO_PYTHON" -m django --version

echo "Tool commands are available. Check the Docker daemon with: sudo docker run --rm hello-world"
if [[ "$DJANGO_PYTHON" == "$VENV_DIR/bin/python" ]]; then
    printf 'To use Django in this shell: source "%s/bin/activate"\n' "$VENV_DIR"
fi
