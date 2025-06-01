function do_setup {
    # update sources.list and then do the usual update-upgrade command
    sudo cp root/etc/apt/sources.list /etc/apt/sources.list
    sudo apt update && sudo apt upgrade -y
}


function do_networking {
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

    # Apply transition by stopping and disabling networking.service and then restarting
    # NetworkManager (resolved and NetworkManager are already enabled upon install)
    sudo systemctl disable networking
    sudo systemctl stop networking
    sudo systemctl restart systemd-resolved wpa_supplicant  # first, dependencies of NM
    sudo systemctl restart NetworkManager

    # connect it to the previously recorded wifi network
    sleep 10 # wait for wifi to be ready
    sudo nmcli device wifi connect "$ssid" password "$psk"
}


function install_services {
    sudo apt install -y \
        systemd-zram-generator
}


function install_utilities {
    sudo apt install -y \
        build-essential htop pkg-config rsync vim
}


function do_root {
    do_networking
    install_services

    # install config files
    sudo cp -rvf --no-preserve=mode,ownership root/etc/* /etc/

    # use the new config files
    sudo update-grub
    sudo systemctl restart systemd-logind
    sudo systemctl restart NetworkManager

    install_utilities
}


function do_user {
    # download and execute miniconda install script
    if [ ! -d ~/miniconda3 ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  \
            -O ~/miniconda3_install.sh
        bash ~/miniconda3_install.sh -b
        rm ~/miniconda3_install.sh
    fi
}


# check if pwd is ~/.dotfiles
if [ ! "$PWD" = "$HOME/.dotfiles" ]; then
    echo "Please run this script from the ~/.dotfiles directory."
    exit 1
fi

do_setup
do_root
do_user
