#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

this=Wallet.GetPublicKey.sh

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
    ## Lock all wallets
    $CleosDir/cleos wallet lock_all
    ## Open the wallet
    Return=$($CleosDir/cleos wallet open -n $AccountName)

    if [[ $Return != "Opened: $AccountName" ]]
    then
        exit 0
    fi

    AttemptsRemaining=5
    while [[ $AttemptsRemaining -gt 0 ]]
    do
        ## Get the wallet password
        if [[ $AccountName == $Eosio ]] || [[ $AccountName == $ProducerName ]]
        then
            ## Stored as plain text for default accounts
            PasswordFile="$WalletDir/$AccountName.password"
            Password=$(cat $PasswordFile)
        else
            ## From user input for created accounts
            Password=$(zenity $GeneralOptions --title="$AccountName.wallet" --password 2> /dev/null)
        fi
   
        if [[ $Password == "" ]]
        then
            $CleosDir/cleos wallet stop
            exit 0
        fi

        Return=$($CleosDir/cleos wallet unlock -n $AccountName --password $Password)
  
        if [[ $Return == "Unlocked: $AccountName" ]]
        then
           ## Get the Public Key
           PublicKey=$($CleosDir/cleos wallet keys) > /dev/null
           PublicKey=$(sed 's/[]"[]*//g' <<< $PublicKey)
           break

         fi
 
         ## Lock all wallets and stop keosd
         $CleosDir/cleos wallet lock_all
         $CleosDir/cleos wallet stop

         AttemptsRemaining=$AttemptsRemaining-1
    done

     ## Lock all wallets and stop keosd
     $CleosDir/cleos wallet lock_all
     $CleosDir/cleos wallet stop

} > /dev/null 2>&1

echo $PublicKey

exit 0
