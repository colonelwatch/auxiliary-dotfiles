#!/bin/bash -e


do_setup() {
    sudo apt update && sudo apt upgrade -y

    # some of the script needs access to curl and unzip first
    sudo apt install -y curl unzip
}


do_root() {
    # use NetworkManager and resolved (for mDNS features)
    sudo apt install -y network-manager systemd-resolved
    __do_network_manager_changeover

    # install liquorix kernel
    curl -s 'https://liquorix.net/install-liquorix.sh' | sudo bash

    # install services
    sudo apt install -y linux-cpupower systemd-zram-generator

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
    if dpkg-query -Wf'${db:Status-abbrev}' network-manager | grep -q '^i'; then
        return 0  # network-manager is already installed, so skip
    fi

    # record wifi config from /etc/network/interfaces
    ssid=$(sudo cat /etc/network/interfaces | grep wpa-ssid | sed 's/\twpa-ssid *//')
    psk=$(sudo cat /etc/network/interfaces | grep wpa-psk | sed 's/\twpa-psk *//')

    # delete wifi config, thus giving control from networking.service to NetworkManager
    temp=$(mktemp)
    sudo cat /etc/network/interfaces | head -8 > "$temp"
    sudo mv "$temp" /etc/network/interfaces

    # Apply transition by restarting networking.service and then restarting
    # NetworkManager (resolved and NetworkManager are already enabled upon install)
    sudo systemctl restart networking
    sudo systemctl restart systemd-resolved wpa_supplicant  # first, dependencies of NM
    sudo systemctl restart NetworkManager

    sleep 10 # wait for NetworkManager to be ready

    if [ -n "$ssid" -a -n "$psk" ]; then
        sudo nmcli device wifi connect "$ssid" password "$psk"
    fi

    if ! ping -c 1 google.com; then
        echo "no internet connection, check nmtui and run again" 1>&2
        return 1
    fi
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
        fd-find fish htop jq man-db ripgrep rsync vim
    pipx install compiledb
    pyenv install 3.12 3.13 3.13t 3.14 3.14t
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
