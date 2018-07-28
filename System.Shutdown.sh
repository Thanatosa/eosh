#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

if [[ $1 != "fast" ]] && [[ $1 != "reboot" ]] && [[ $1 != "" ]]
then 
    echo "Usage: Shutdown.sh [fast] [reboot]"
    exit 0
fi

if [[ $2 != "fast" ]] && [[ $2 != "reboot" ]] && [[ $2 != "" ]]
then
    echo "Usage: Shutdown.sh [fast] [reboot]"
    exit 0
fi

sleep 0.1

## Terminate the processes
if [[ $(pgrep eoshGUI.sh) != "" ]]
then 
    kill -SIGTERM $(pgrep eoshGUI.sh)
fi

if [[ $(pgrep zenity) != "" ]]
then 
    kill -SIGTERM $(pgrep zenity)
fi

if [[ $(pgrep keosd) != "" ]]
then 
    kill -SIGTERM $(pgrep keosd)
fi

if [[ $(pgrep nodeos) != "" ]]
then 
    kill -SIGTERM $(pgrep nodeos)
fi

## Wait for processes to be terminated
Seconds=10
while [[ $Seconds -gt 0 ]]
do
    RemainingProcesses=$(pgrep eoshGUI.sh)$(pgrep zenity)$(pgrep keosd)$(pgrep nodeos)
    if [[ $RemainingProcesses == "" ]]
    then
        break
    fi
    let Seconds-=1
    sleep 1
done

if [[ $Seconds == 0 ]]
then
   echo "Warning: could not terminate all processes"
fi 

## Terminate bash terminals
if [[ $(pgrep bash) != "" ]]
then 
    kill -SIGTERM $(pgrep bash)
fi

## Wait for bash terminals to be terminated, apart from this one
Seconds=10
ParentPID=$(echo $PPID)
while [[ $Seconds -gt 0 ]]
do
    RemainingProcesses=$(pgrep bash)
    if [[ $RemainingProcesses == "" ]] || [[ $RemainingProcesses == $ParentPID ]]
    then
        break
    fi
    let Seconds-=1
    sleep 1
done

if [[ $Seconds == 0 ]]
then
   echo "Warning: could not terminate all bash terminals"
fi 

## Clear RAM
if [[ $1 = "fast" ]] || [[ $2 = "fast" ]]
then
    sdmem -f -ll
else
    sdmem
fi

## Shutdown the system
if [[ $1 = "reboot" ]] || [[ $2 = "reboot" ]]
then
    shutdown -r now
else
    shutdown -P now
fi

exit 0
