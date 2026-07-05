#!/bin/bash -e


do_setup() {
    # update sources.list and then do the usual update-upgrade command
    sudo cp root/etc/apt/sources.list /etc/apt/sources.list
    sudo apt update && sudo apt upgrade -y

    # some of the script needs access to curl first
    sudo apt install -y curl
}


do_root() {
    # install liquorix kernel
    curl -s 'https://liquorix.net/install-liquorix.sh' | sudo bash

    # install services
    sudo apt install -y linux-cpupower systemd-zram-generator

    # install config files
    sudo cp -rvf --no-preserve=mode,ownership root/etc/* /etc/

    # other setup
    sudo update-grub
    __do_networking
}


__do_networking() {
    if dpkg-query -Wf'${db:Status-abbrev}' network-manager | grep -q '^i'; then
        return 0  # network-manager is already installed, so skip
    fi

    # install packages for NetworkManager and resolved (for mDNS features)
    sudo apt install -y network-manager systemd-resolved

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

    if [ -z "$ssid" -o -z "$psk" ]; then
        return 0  # no WiFi network to connext to
    fi

    # connect it to the previously recorded wifi network
    sleep 10 # wait for wifi to be ready
    sudo nmcli device wifi connect "$ssid" password "$psk"
}


do_user() {
    # install applications
    sudo apt install -y \
        bats bats-assert bats-support bats-file build-essential cmake htop  \
        rsync vim

    __install_neovim
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
