#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

{
    (
        LastBlockNum=0
        while [[ true ]]
        do
            sleep 0.5
            Info=$($CleosDir/cleos get info) 2> $LogDir/LocalBlockMonitor.err.log
            BlockNum=$(awk '/"head_block_num": /{print $2}' <<< $Info)
            BlockNum=$(sed 's/,//g' <<<$BlockNum)
            Producer=$(awk '/"head_block_producer": /{print $2}' <<< $Info)
            Producer=$(sed 's/,//g' <<<$Producer)
            Producer=$(sed 's/"//g' <<<$Producer)
            if [[ $BlockNum != "" ]]
            then
                if [[ $BlockNum -gt $LastBlockNum ]]
                then
                    echo "$Block_Monitor_Block: $BlockNum   $Producer"
                elif  [[ $BlockNum -lt $LastBlockNum ]]
                then
                    echo "########################"
                    echo "$Block_Monitor_Block: $BlockNum   $Producer"
                fi
                LastBlockNum=$BlockNum
            fi
        done
    )  | zenity $GeneralOptions --width=480 --height=128 --text-info --auto-scroll
} 2> /dev/null

exit 0
