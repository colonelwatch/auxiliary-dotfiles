# <SETUP>

# check if pwd is ~/.dotfiles
if [ ! "$PWD" = "$HOME/.dotfiles" ]; then
    echo "Please run this script from the ~/.dotfiles directory."
    exit 1
fi

sudo mkdir -p --mode=0755 /usr/share/keyrings

# add zram-generator repo
sudo wget https://nabijaczleweli.xyz/pgp.txt -O /etc/apt/keyrings/nabijaczleweli.asc
echo 'deb [signed-by=/etc/apt/keyrings/nabijaczleweli.asc] https://debian.nabijaczleweli.xyz bookworm main' | sudo tee -a /etc/apt/sources.list.d/zram-generator.list
echo 'deb-src [signed-by=/etc/apt/keyrings/nabijaczleweli.asc] https://debian.nabijaczleweli.xyz bookworm main' | sudo tee -a /etc/apt/sources.list.d/zram-generator.list

# update sources.list
sudo cp root/etc/apt/sources.list /etc/apt/sources.list

sudo apt update && sudo apt upgrade -y

# </SETUP>



# <ROOT>

# record wifi config from /etc/network/interfaces
SSID=$(sudo cat /etc/network/interfaces | grep wpa-ssid | sed 's/\twpa-ssid *//')
PSK=$(sudo cat /etc/network/interfaces | grep wpa-psk | sed 's/\twpa-psk *//')

# install NetworkManager and resolved (for mDNS features) and stop networking.service from using the wifi
temp=$(mktemp)
sudo apt install -y network-manager systemd-resolved
sudo cat /etc/network/interfaces | head -8 > "$temp"  # prepare interfaces files without wifi config
sudo mv "$temp" /etc/network/interfaces
sudo systemctl disable networking
sudo systemctl stop networking
sudo systemctl restart systemd-resolved wpa_supplicant
sudo systemctl restart NetworkManager

# connect it to the previously recorded wifi network
sleep 10 # wait for wifi to be ready
sudo nmcli device wifi connect "$SSID" password "$PSK"

sudo apt install -y \
    systemd-zram

# install config files
sudo cp -rvf --no-preserve=mode,ownership root/etc/* /etc/

# use the new config files
sudo update-grub
sudo systemctl restart systemd-logind
sudo systemctl restart NetworkManager

# </ROOT>



# <USER>

sudo apt install -y \
    build-essential ffmpeg fish htop parallel pkg-config rsync screen vim

# download and execute miniconda install script
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3_install.sh
bash ~/miniconda3_install.sh -b # conda will soon be intialized by importing the fish config
rm ~/miniconda3_install.sh

# install config files
mkdir -p ~/.config
ln -s -f $PWD/config/* ~/.config/

# </USER>



# <CLEANUP>

# </CLEANUP>