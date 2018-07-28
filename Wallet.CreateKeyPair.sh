#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

{
    Display=$($CleosDir/cleos create key)
    zenity $GeneralOptions --ellipsize --info --text="$Display" 2> /dev/null

} > /dev/null 2>&1

exit 0
