#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

## Install version control, compiler, secure RAM deletion and the QR code reader
sudo apt install git
sudo apt install gcc
sudo apt install net-tools
sudo apt install secure-delete
sudo apt install qrencode

## Get and build the eosio code
git clone https://github.com/EOSIO/eos --recursive
chmod +x ~/eosh/install/Build.sh
~/eosh/install/Build.sh

## Disable network devices
sudo cp /etc/network/interfaces /etc/network/interfaces.bak
sudo chmod a+rw /etc/network/interfaces
NetworkDevices=$(ifconfig | sed 's;^\(.*\): flags=\(.*\)$;iface \1 inet manual;g')
NetworkDevices=$(echo "$NetworkDevices" | sed 's;^ \(.*\)$;;g')
NetworkDevices=$(echo "$NetworkDevices" | sed '/^\s*$/d')
NetworkDevices=$(echo "$NetworkDevices" | sed 's;iface lo inet manual;;g')
echo "$NetworkDevices" >> /etc/network/interfaces

## Disable Swap Disk
sudo cp /etc/fstab /etc/fstab.bak
sudo chmod a+rw /etc/fstab
sudo sed -i.bak 's;/swapfile;#/swapfile;g' /etc/fstab

## Disable ptrace
sudo cp /etc/sysctl.d/10-ptrace.conf /etc/sysctl.d/10-ptrace.bak
sudo chmod a+rw /etc/sysctl.d/10-ptrace.conf
sudo sed -i "s/kernel.yama.ptrace_scope = \(.\)/kernel.yama.ptrace_scope = 3/g" /etc/sysctl.d/10-ptrace.conf

## Install icon
IconPath=/usr/share/icons/hicolor

sudo cp ~/eosh/icons/256x256.png $IconPath/256x256/apps/eoshGUI.png
sudo cp ~/eosh/icons/128x128.png $IconPath/128x128/apps/eoshGUI.png
sudo cp ~/eosh/icons/64x64.png $IconPath/64x64/apps/eoshGUI.png
sudo cp ~/eosh/icons/32x32.png $IconPath/32x32/apps/eoshGUI.png
sudo cp ~/eosh/icons/16x16.png $IconPath/16x16/apps/eoshGUI.png

EoshDir="$(echo ~/eosh)"
cp ~/eosh/install/eoshGUI.launcher ~/Desktop/eoshGUI.desktop
chmod -c +x ~/Desktop/eoshGUI.desktop
sudo sed -i "s;EOSH_PATH;$EoshDir;g" ~/Desktop/eoshGUI.desktop

cp ~/eosh/install/eoshGUI.launcher ~/.local/share/applications/eoshGUI.desktop
chmod -c +x ~/.local/share/applications/eoshGUI.desktop
sudo sed -i "s;EOSH_PATH;$EoshDir;g" ~/.local/share/applications/eoshGUI.desktop

sudo chmod o+r $IconPath/256x256/apps/eoshGUI.png 
sudo chmod o+r $IconPath/128x128/apps/eoshGUI.png 
sudo chmod o+r $IconPath/64x64/apps/eoshGUI.png 

sudo gtk-update-icon-cache $IconPath

sudo chmod +x ~/eosh/*.sh

## Reboot
echo "Reboot required to complete installation"
read -s -p "Press a key to reboot when ready" -n 1
echo
shutdown -r now

