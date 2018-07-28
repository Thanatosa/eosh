#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

## Clear node
kill -SIGTERM $(pgrep nodeos)
rm -rd ~/.local/share/eosio/nodeos

PasswordFile="$WalletDir/$Eosio.password"
EosioPassword=$(cat $PasswordFile)
Pubkey=$(~/eosh/Wallet.GetPublicKey.sh $Eosio)

## Start child process for producing
/bin/bash ~/eosh/Local.Producer.sh $Eosio & > $LogDir/$Eosio.out.log 2> $LogDir/$Eosio.err.log

{
    ## Wait for node to start producing
    while [[ $($CleosDir/cleos get info) == "" ]]
    do
        echo "wait"
        sleep 1
    done

    $CleosDir/cleos wallet open   -n $Eosio
    $CleosDir/cleos wallet unlock -n $Eosio --password $EosioPassword
    $CleosDir/cleos create account $Eosio eosio.bpay   $Pubkey
    $CleosDir/cleos create account $Eosio eosio.msig   $Pubkey
    $CleosDir/cleos create account $Eosio eosio.names  $Pubkey
    $CleosDir/cleos create account $Eosio eosio.ram    $Pubkey
    $CleosDir/cleos create account $Eosio eosio.ramfee $Pubkey
    $CleosDir/cleos create account $Eosio eosio.saving $Pubkey
    $CleosDir/cleos create account $Eosio eosio.stake  $Pubkey
    $CleosDir/cleos create account $Eosio eosio.token  $Pubkey
    $CleosDir/cleos create account $Eosio eosio.vpay   $Pubkey

    ## Set Contracts and issue tokens
    emptycodehash="code hash: 0000000000000000000000000000000000000000000000000000000000000000"

    while [[ $($CleosDir/cleos get code eosio.msig)  == "$emptycodehash" ]]
    do
       $CleosDir/cleos set contract eosio.msig $ContractDir/eosio.msig
    done
    
    while [[ $($CleosDir/cleos get code eosio.token)  == "$emptycodehash" ]]
    do
       $CleosDir/cleos set contract eosio.token $ContractDir/eosio.token
    done

    $CleosDir/cleos push action eosio.token create '[ "eosio", "10000000000.0000 EOS", 0, 0, 0]' -p eosio.token
    $CleosDir/cleos push action eosio.token issue  '[ "eosio", "1000000000.0000 EOS", "memo"]' -p eosio

    codehash=$emptycodehash
    while [[ $($CleosDir/cleos get code $Eosio)  == "$emptycodehash" ]]
    do
       $CleosDir/cleos set contract $Eosio $ContractDir/eosio.system -p $Eosio
    done

    ## Lock Wallets
    $CleosDir/cleos wallet lock_all

    # Get the public key from the wallet for producer account
    ProducerPublicKey=$(~/eosh/Wallet.GetPublicKey.sh $ProducerName)

    StakeNet="100000000.0000 EOS"
    StakeCPU="100000000.0000 EOS"
    MemKB=8

    $CleosDir/cleos wallet open   -n $Eosio
    $CleosDir/cleos wallet unlock -n $Eosio --password $EosioPassword
    $CleosDir/cleos system newaccount --transfer --stake-net "$StakeNet" --stake-cpu "$StakeCPU" --buy-ram-kbytes $MemKB $Eosio $ProducerName $ProducerPublicKey
    $CleosDir/cleos wallet lock_all

    ## Get the password for the producer wallet
    PasswordFile="$WalletDir/$ProducerName.password"
    ProducerPassword=$(cat $PasswordFile)

    ## Register the producer and vote
    $CleosDir/cleos wallet open   -n $ProducerName
    $CleosDir/cleos wallet unlock -n $ProducerName --password $ProducerPassword
    $CleosDir/cleos system regproducer $ProducerName $ProducerPublicKey "http://$ProducerName.com" 0
    $CleosDir/cleos system voteproducer prods $ProducerName $ProducerName

    # Lock Wallets and stop wallet process
    $CleosDir/cleos wallet lock_all
    $CleosDir/cleos wallet stop

    # Wait for the node to process the previous transactions then kill it
    sleep 4
    kill -SIGTERM $(pgrep nodeos)
    sleep 1

} > $LogDir/LaunchNewChain.out.log 2> $LogDir/LaunchNewChain.err.log

## Start production with new producer
/bin/bash ~/eosh/Local.Producer.sh $ProducerName & > $LogDir/$ProducerName.out.log 2> $LogDir/$ProducerName.err.log

