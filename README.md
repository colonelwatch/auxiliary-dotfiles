# auxiliary-dotfiles

Oh, I'll end up nuking my auxiliary server for sure, so this repo documents everything I need to set it up from scratch, including a bootstrap script and a recovery script.

## Pre-install

0. Enable Wake On AC and set a battery charge limit at 70%

1. Disable warnings about the power adapter having insufficient wattage

## Install

2. Booting from the install disk for Debian 13, proceed through the non-graphical install process
   - Time zone, keyboard, and language are self-explanatory
   - Make sure to use Wi-Fi during setup
   - The hostname should be `kenny-auxiliary`
   - Disable the root user (leave the root password empty)
   - Set up the disk as follows:
     - Select a manual install
     - Delete every partition on the disk
     - Create a 1 GB partition (starting from the beginning of the disk) with the EFI file system
     - Create a partition with all the remaining free space with the BTRFS file system and a mount point of `/`
     - Finish setup, and dismiss the warning about not designating swap
   - Turn off all desktop environments and turn on the SSH server

## Post-install

3. Install `git` with the command `sudo apt install git`

4. Clone this repository with the command `git clone https://github.com/colonelwatch/auxiliary-dotfiles .dotfiles --recurse-submodules`, call `cd .dotfiles && ./bootstrap.sh`

5. Authorize thunderbolt dock through `boltctl`

6. Restart

## Post-boostrap

7. Authorize Git over HTTPS with GitHub with the command `gh auth login`.
