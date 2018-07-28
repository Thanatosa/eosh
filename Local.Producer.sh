#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

this=Local.Producer.sh

if [[ ! $1 =~ ^[1-5,a-z,\.]{1,12}$ ]]
then
   echo "Usage: $this ProducerAccountName"
   exit 0
fi

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

Producer=$1
ExtraFlag=$2

ProducerPublicKey=$(~/eosh/Wallet.GetPublicKey.sh $Producer)
ProducerPrivateKey=$(~/eosh/Wallet.GetPrivateKey.sh $Producer)
SignatureString=$ProducerPublicKey"=KEY:"$ProducerPrivateKey

$NodeosDir/nodeos -e $ExtraFlag -p $Producer --signature-provider $SignatureString --plugin eosio::producer_plugin --plugin eosio::chain_api_plugin --plugin eosio::http_plugin --plugin eosio::history_api_plugin > $LogDir/$Producer.out.log 2> $LogDir/$Producer.err.log
