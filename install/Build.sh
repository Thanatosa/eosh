#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

## Reduce physical memory requirement for building eosio 
Original="if \[ \"\${MEM_MEG}\" \-lt 7000 ]; then"
Replaced="if \[ \"\${MEM_MEG}\" \-lt 4000 ]; then"
sed -i "s/$Original/$Replaced/g" ~/eos/scripts/eosio_build_*.sh

## Fix bug in which prevents the eosio code running without remote host
WS="[ \t]*"
Original="tcp::resolver::query[ \t]*query[ \t]*([ \t]*tcp::v4()[ \t]*,[ \t]*host.c_str()[ \t]*,[ \t]*port.c_str()[ \t]*)"
Replaced="tcp::resolver::query query( tcp::v4(), host.c_str(), port.c_str(), boost::asio::ip::resolver_query_base::flags())"
sed -i "s/$Original/$Replaced/g" ~/eos/plugins/http_plugin/http_plugin.cpp
sed -i "s/$Original/$Replaced/g" ~/eos/plugins/net_plugin/net_plugin.cpp

## Build eosio code
LogDir=~/eosh/logs
cd ~/eos
~/eos/eosio_build.sh -s EOS

## Copy executables
mkdir -p ~/eosh/bin/cleos
mkdir -p ~/eosh/bin/nodeos
mkdir -p ~/eosh/bin/keosd
cp ~/eos/build/programs/cleos/cleos   ~/eosh/bin/cleos/cleos
cp ~/eos/build/programs/nodeos/nodeos ~/eosh/bin/nodeos/nodeos
cp ~/eos/build/programs/keosd/keosd   ~/eosh/bin/keosd/keosd

## Copy system contracts
mkdir -p ~/eosh/contracts/eosio.msig
mkdir -p ~/eosh/contracts/eosio.system
mkdir -p ~/eosh/contracts/eosio.token
cp -r ~/eos/build/contracts/eosio.msig/*.{wasm,wast,abi}   ~/eosh/contracts/eosio.msig/
cp -r ~/eos/build/contracts/eosio.system/*.{wasm,wast,abi} ~/eosh/contracts/eosio.system/
cp -r ~/eos/build/contracts/eosio.token/*.{wasm,wast,abi}  ~/eosh/contracts/eosio.token/

exit 0

