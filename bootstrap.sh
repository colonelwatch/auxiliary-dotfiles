#!/bin/bash -e


do_setup() {
    # launch a sudoloop
    sudo -v
    while true; do sudo -n -v; sleep 60; kill -0 $$ 2> /dev/null || exit; done &

    # some of the script needs access to curl and unzip first
    sudo apt install -y curl unzip

    # update sources and do an apt update/upgrade
    sudo cp root/etc/apt/sources.list /etc/apt/
    sudo apt update && sudo apt upgrade -y
}


do_root() {
    # use NetworkManager and resolved (for mDNS features)
    sudo apt install -y network-manager systemd-resolved    \
        && __do_network_manager_changeover

    # install kernel and drivers
    sudo apt install -y nvidia-open-kernel-dkms nvidia-driver

    # install services
    sudo apt install -y bolt linux-cpupower systemd-zram-generator

    # install config files
    sudo cp -rvf --no-preserve=mode,ownership root/etc/* /etc/

    # enable services
    sudo systemctl daemon-reload
    sudo systemctl enable   \
        cpupower-performance.service

    # other setup
    sudo update-grub
}


__do_network_manager_changeover() {
    if sudo cmp -s root/etc/network/interfaces /etc/network/interfaces; then
        return 0  # nothing to be done
    fi

    # record wifi config from /etc/network/interfaces
    local ssid psk
    ssid=$(
        sudo grep wpa-ssid /etc/network/interfaces |    \
            head -n1 |                                  \
            sed 's/^[[:space:]]*wpa-ssid[[:space:]]*//' \
        || true
    )
    psk=$(
        sudo grep wpa-psk /etc/network/interfaces |     \
            head -n1 |                                  \
            sed 's/^[[:space:]]*wpa-psk[[:space:]]*//'  \
        || true
    )

    do_service_restart() {
        sudo systemctl restart networking
        sudo systemctl restart  \
            systemd-resolved wpa_supplicant  # NetworkManager dependencies first
        sudo systemctl restart NetworkManager
    }

    # install a basic interfaces file, preparing to move control from
    # networking.service to NetworkManager
    # NOTE: if any of the below steps fail, the Wi-Fi credentials are preserved
    sudo cp /etc/network/interfaces /etc/network/interfaces.bak
    # shellcheck disable=SC2329  # SC2329 is a false positive for trap functions
    do_revert() {
        trap - RETURN EXIT
        sudo mv /etc/network/interfaces.bak /etc/network/interfaces
        do_service_restart
        unset -f do_revert do_service_restart
    }
    trap do_revert RETURN EXIT
    sudo cp root/etc/network/interfaces /etc/network/interfaces

    # apply transition and wait for NetworkManager to be ready
    do_service_restart
    sleep 10

    if [ -n "$ssid" ]; then
        local connect_args=("$ssid")
        if [ -n "$psk" ]; then
            connect_args+=(password "$psk")
        fi
        sudo nmcli device wifi connect "${connect_args[@]}"
    fi

    if ! ping -c 1 google.com; then
        echo "changeover broke the internet connection, reverting..." 1>&2
        return 1
    fi

    trap - RETURN EXIT
    sudo rm /etc/network/interfaces.bak
    unset -f do_revert do_service_restart
}


do_user() {
    # install package managers
    sudo apt install -y pipx  # pipx
    curl -fsSL https://pyenv.run | bash && __source_pyenv  # pyenv
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |     \
        sh -s -- -y && . "$HOME/.cargo/env"  # cargo
    curl -fsSL https://fnm.vercel.app/install |     \
        bash -s -- --skip-shell && __source_fnm  # fnm

    # install pyenv dependencies (Python build dependencies)
    sudo apt install -y \
        make build-essential libssl-dev zlib1g-dev libbz2-dev               \
        libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils   \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libzstd-dev

    # install applications
    sudo apt install -y \
        bats bats-assert bats-support bats-file build-essential cmake clang \
        fd-find fish git-lfs htop jq man-db ripgrep rsync vim
    pipx install compiledb
    pyenv install --skip-existing 3.12 3.13 3.13t 3.14 3.14t
    cargo install --locked tree-sitter-cli yazi-build macchina
    fnm install --lts  # nodejs and npm
    __install_neovim

    # set fish as default shell
    sudo chsh -s /usr/bin/fish kenny

    # install config files
    mkdir -p ~/.config
    ln -s -f $PWD/home/.config/* ~/.config/
}


__source_pyenv() {
    export PYENV_ROOT="$HOME/.pyenv"
    if [ -d "$PYENV_ROOT/bin" ]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    eval "$(pyenv init - bash)"

    export PYTHON_CONFIGURE_OPTS='--enable-optimizations --with-lto'
    export PYTHON_CFLAGS='-march=native -mtune=native'
    export MAKE_OPTS="-j$(nproc)"
}


__source_fnm() {
    FNM_PATH="/home/kenny/.local/share/fnm"
    if [ -d "$FNM_PATH" ]; then
      export PATH="$FNM_PATH:$PATH"
      eval "$(fnm env --shell bash)"
    fi
}


__install_neovim() (
    tmpdir=$(mktemp -d)
    cd "$tmpdir"
    git clone --depth 1 -b stable https://github.com/neovim/neovim
    cd neovim
    make CMAKE_BUILD_TYPE=Release                               \
        CMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG -march=native"      \
        CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.local"
    make install
)


# check if pwd is ~/.dotfiles
if [ ! "$PWD" = "$HOME/.dotfiles" ]; then
    echo "Please run this script from the ~/.dotfiles directory."
    exit 1
fi

do_setup
do_root
do_user
