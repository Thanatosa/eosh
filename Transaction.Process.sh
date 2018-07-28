#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

this=Transaction.Process.sh

if [[ ! $1 =~ ^[1-5,a-z,\.]{1,12}$ ]]
then
   echo "Usage: $this AccountName Transaction local"
   echo "Usage: $this AccountName Transaction mainnet RefBlockNum RefBlockPrefix"
   exit 0
fi

if [[ $3 = "mainnet" ]]
then
   if [[ ! $4 =~ ^[0-9]+$ ]]  || [[ ! $5 =~ ^[0-9]+$ ]]
   then
       echo "Usage: $this AccountName Transaction mainnet RefBlockNum RefBlockPrefix"
      exit 0 
   fi
fi

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

AccountName=$1
Transaction=$2
ChainName=$3

## Set chain information
if [[ $ChainName = "mainnet" ]]
then
   ChainID=aca376f206b8fc25a6ed44dbdc66547c36c6c33e3a119ffbeaef943642f0e906
   RefBlockNum=$4
   RefBlockPrefix=$5
else
   if [[ $ChainName = "local" ]]
   then
      ChainID=cf057bbfb72640471fd910bcb67639c22df9f92470936cddc1ade0e2f2e7dc4f

      Info=$($CleosDir/cleos get info) 2> $LogDir/Transaction.Process.err.log
      Info=$(awk '/"head_block_num": /{print $2}' <<< $Info)
      RefBlockNum=$(sed 's/,//g' <<<$Info)

      Block=$($CleosDir/cleos get block $RefBlockNum) 2> $LogDir/Transaction.Process.err.log
      Block=$(awk '/"ref_block_prefix": /{print $2}' <<< $Block)
      RefBlockPrefix=$(sed 's/,//g' <<<$Block)
   else
      exit 0
   fi
fi

## Set transaction filenames
TxDir=~/eosh/transactions
UnsignedFile=$TxDir/$Transaction.unsigned
ModifiedFile=$TxDir/$Transaction.modified
SignedFile=$TxDir/$Transaction.signed
RPCFile=$TxDir/$Transaction.rpc
QRImage=$TxDir/$Transaction.png
ReceiptFile=$TxDir/$Transaction.receipt

## Inject Reference Block Data
#RefBlockNum=$(($RefBlockNum%65536))
Match1='"ref_block_num": '
Match2='"ref_block_prefix": '
cp $UnsignedFile $ModifiedFile
sed -i "s/$Match1[0-9]*/$Match1$RefBlockNum/g" $ModifiedFile
sed -i "s/$Match2[0-9]*/$Match2$RefBlockPrefix/g" $ModifiedFile

## Sign Transaction
PrivateKey=$(/bin/bash ~/eosh/Wallet.GetPrivateKey.sh $AccountName)
$CleosDir/cleos sign -k $PrivateKey -c $ChainID $ModifiedFile > $SignedFile 2> $LogDir/Transaction.Process.err.log
PrivateKey=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

## Process Signed Transaction
if [[ $ChainName = "mainnet" ]]; then
    ## Generate RPC file
    RPCTransaction=$(tr -d '\n' < $SignedFile)
    RPCTransaction=$(echo $RPCTransaction | sed '{s/ //g}')
    RPCTransaction=$(echo $RPCTransaction | sed '0,/{/s//{"compression":"none","transaction":{/')
    Signatures=$(echo $RPCTransaction | sed '{s/.*"signatures":\[//g}')
    Signatures=$(echo $Signatures | sed '{s/],.*//g}')
    RPCTransaction=$(echo $RPCTransaction | sed '{s/"signatures":\[.*],//g}')
    RPCTransaction=$RPCTransaction',"signatures":['$Signatures']}'
    echo $RPCTransaction > $RPCFile
    ## Generate QR code
    qrencode -o $QRImage -t png <$RPCFile
    eog $QRImage
elif [[ $ChainName = "local" ]]; then
  ## Push signed transaction
  $CleosDir/cleos push transaction $SignedFile > $ReceiptFile 2> $LogDir/Transaction.Process.err.log
fi

exit 0
