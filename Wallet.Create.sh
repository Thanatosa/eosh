#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

this=Wallet.Create.sh

if [[ ! $1 =~ ^[1-5,a-z,\.]{1,12}$ ]]
then
   echo "Usage: $this AccountName"
   exit 0
fi

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

AccountName=$1

{
    PasswordString=$($CleosDir/cleos wallet create -n $AccountName)
    echo $PasswordString
    
    if [[ $PasswordString != "" ]]
    then
        PrivateKey=$(zenity $GeneralOptions --entry --text="Private Key" 2> /dev/null)

        if [[ $PrivateKey == "" ]]
        then
           exit 0
        fi

        ReturnString=$($CleosDir/cleos wallet import -n $AccountName --private-key $PrivateKey)
        if [[ $ReturnString != "" ]]
        then
            zenity $GeneralOptions --ellipsize --info --text="$PasswordString" 2> /dev/null
        else
            zenity $GeneralOptions --ellipsize --info --text="Failed import private key. Is it valid?" 2> /dev/null
        fi
    else
        zenity $GeneralOptions --ellipsize --info --text="Failed to create wallet. Does it already exist?" 2> /dev/null
    fi

} > /dev/null 2>&1

exit 0
