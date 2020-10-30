#!/bin/bash


set -e

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
}

# To note: the execute() function doesn't handle pipes well
execute () {
	echo "$ $*"
	OUTPUT=$($@ 2>&1)
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
else
    MJOBS=4
fi

execute sudo apt-get update -y
if [[ ! -n $CIINSTALL ]]; then
    sudo apt-get dist-upgrade -y
    sudo apt-get install ubuntu-restricted-extras -y
fi

# Choice for terminal that will be adopted: Alacritty+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
execute sudo apt-get install git wget curl -y
execute sudo add-apt-repository ppa:mmstick76/alacritty
execute sudo apt install alacritty -y
execute sudo apt-get install tmux -y
execute sudo apt-get install gimp -y
execute sudo apt-get install xclip xsel -y # this is used for the copying tmux buffer to clipboard buffer

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/tmux.conf ~/.tmux.conf
cp ./config_files/tmux.conf.local ~/.tmux.conf.local

# For utilities such as lspci
execute sudo apt-get install pciutils

## Detect if an Nvidia card is attached, and install the graphics drivers automatically
if [[ -n $(lspci | grep -i nvidia) ]]; then
    spatialPrint "Installing Display drivers and any other auto-detected drivers for your hardware"
    execute sudo add-apt-repository ppa:graphics-drivers/ppa -y
    execute sudo apt-get update
    execute sudo ubuntu-drivers autoinstall
fi

spatialPrint "The script has finished."
if [[ ! -n $CIINSTALL ]]; then
    su - $USER
fi
