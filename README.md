# auxiliary-dotfiles

Oh, I'll end up nuking my auxiliary server for sure, so this repo documents everything I need to set it up from scratch, including a bootstrap script and a recovery script.

## Pre-install

0. Enable Wake On AC and set a battery charge limit at 70%

## Install

1. Booting from the install disk for Debian 12 (non-free drivers now included by default), proceed through the non-graphical install process.
    * Time zone, keyboard, and language are self-explanatory
    * Disable the root user (leave the root password empty)
    * The hostname should be `kenny-auxiliary`
    * Nuke all partitions, single-partition install, and no swap partition (delete it after guided partitioning but before continuing, proceed through the warning about not designating swap)
    * Turn off all desktop environments and turn on the SSH server

## Post-install

2. Install `git` with the command `sudo apt install git`

3. Clone this repository with the command `git clone https://github.com/colonelwatch/auxiliary-dotfiles .dotfiles`, call `cd .dotfiles && bash ./bootstrap.sh`

4. Authorize thunderbolt dock through `boltctl`

5. Restart

## Post-bootstrap

6. SSH with tunneling into the server by running the command `ssh -L 53682:localhost:53682 kenny@kenny-auxiliary` on another machine with a web browser

7. Call `cd .dotfiles && bash ./recovery.sh`, which includes manual prompts and recovery