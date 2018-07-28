#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

## Terminate existing nodoes processes
if [[ $(pidof nodeos) != "" ]]
then
    kill -SIGTERM $(pgrep nodeos)
fi

Seconds=0
while [[ $Seconds -lt 5 ]]
do
    sleep 1
    Seconds=$((Seconds+1))
    if [[ $(pidof nodeos) == "" ]]
    then
        break
    fi
done

if [[ $(pidof nodeos) != "" ]]
then
    echo "Couldn't terminate existing nodeos processes" > $LogDir/Local.StartChain.err.log
    exit 0
fi

## If node isn't running then try running it from the producer account
echo "Launching with $ProducerName" > $LogDir/Local.StartChain.out.log
( 
    /bin/bash ~/eosh/Local.Producer.sh $ProducerName &
   
    ## Wait for cleos to respond
    Seconds=0
    while [[ $Seconds -lt 5 ]]
    do
        sleep 1
        Seconds=$((Seconds+1))
        if [[ $($CleosDir/cleos get info) != "" ]] 2> $LogDir/Local.StartChain.err.log
        then
            break
        fi
    done
    echo 100
) | zenity --progress $GeneralOptions --no-cancel --auto-close --text="Starting Chain" 2> /dev/null

## Try hard replay
Info=$($CleosDir/cleos get info) 2> $LogDir/Local.StartChain.err.log
if [[ $Info == "" ]]
then
    (
        echo "Hard Replay"
        /bin/bash ~/eosh/Local.Producer.sh $ProducerName --hard-replay-blockchain &

        ## Wait for cleos to respond
        Seconds=0
        while [[ $Seconds -lt 5 ]]
        do
            sleep 1
            Seconds=$((Seconds+1))

            Info=$($CleosDir/cleos get info) 2> $LogDir/Local.StartChain.err.log
            if [[ $Info != "" ]]
            then
                break
            fi
        done

        ## Update progress
        if [[ $Info != "" ]]
        then
            while [[ $($CleosDir/cleos get info) != *"$ProducerName"* ]] 2> $LogDir/Local.StartChain.err.log
            do
                sleep 2
                String=$(cat $LogDir/soloproducer.err.log)
                String=$(echo $String | sed 's;\r;;g') 
                Total=$(echo $String | sed 's;.* of ;;g') 
                Block=$(echo $String | sed 's; of \([0-9]*\);;g')
                Block=$(echo $Block | sed 's;.* ;;g')
                Percent=$(($Block*100/$Total))
                echo $Percent
            done
        fi
        echo 100
    ) | zenity --progress $GeneralOptions --no-cancel --auto-close --text="$Start_Chain_Replaying_Chain" 2> /dev/null
fi

## Launch new chain
Info=$($CleosDir/cleos get info) 2> $LogDir/Local.StartChain.err.log
if [[ $Info == "" ]] || [[ $Info == *"\"head_block_producer\": \"\""* ]]
then
    echo "Launch new chain"
    /bin/bash ~/eosh/Local.LaunchNewChain.sh &

    ## Wait for cleos to respond
    Seconds=0
    while [[ $Seconds -lt 5 ]]
    do
        sleep 1
        Seconds=$((Seconds+1))

        Info=$($CleosDir/cleos get info) 2> $LogDir/Local.StartChain.err.log
        if [[ $Info != "" ]]
        then
            break
        fi
    done

    ## Show progress
    if [[ $Info != "" ]]
    then
        Count=0
        (
            while [[ $($CleosDir/cleos get info) != *"$ProducerName"* ]] 2> $LogDir/Local.StartChain.err.log
            do
                sleep 1
                Count=$(($Count+10))
                if [[ $Count -gt 90 ]]
                then
                    Count=99
                fi
                echo $Count
            done
            echo 100
        ) | zenity --progress $GeneralOptions --no-cancel --auto-close --text="$Start_Chain_Launching_New_Chain" 2> /dev/null
    fi
fi

exit 0
