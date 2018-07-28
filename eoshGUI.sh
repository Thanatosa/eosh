#!/bin/bash

################################
## Copyright(c) 2018 Thanatos ##
## t.me/Thanatosa             ##
################################

source ~/eosh/StringTable
source ~/eosh/CommonDefinitions
cd ~/eosh

if [[ $(pgrep -f eoshGUI.sh) != $$ ]]
then
    zenity $GeneralOptions --ellipsize --info --no-markup --text="$Already_Running" 2> /dev/null
    exit 0
fi


mkdir -p $TransactionDir
mkdir -p $LogDir
mkdir -p $BackupDir

## Build the binaries if not already present
Dependencies=(
~/eosh/bin/cleos/cleos
~/eosh/bin/nodeos/nodeos
~/eosh/bin/keosd/keosd
~/eosh/contracts/eosio.msig/eosio.msig.abi
~/eosh/contracts/eosio.msig/eosio.msig.wast
~/eosh/contracts/eosio.msig/eosio.msig.wasm
~/eosh/contracts/eosio.system/eosio.system.abi
~/eosh/contracts/eosio.system/eosio.system.wast
~/eosh/contracts/eosio.system/eosio.system.wasm
~/eosh/contracts/eosio.token/eosio.token.abi
~/eosh/contracts/eosio.token/eosio.token.wast
~/eosh/contracts/eosio.token/eosio.token.wasm)

Build=false
for i in "${Dependencies[@]}"
do
    if [[ $(ls $i) == "" ]]
    then
        Build=true
    fi
done

if [[ $Build == true ]]
then
   /bin/bash ~/eosh/install/Build.sh & > $LogDir/Build.out.txt 2> $LogDir/Build.err.txt
fi

{
   (
       while [[ $Build == true ]]
       do
           sleep 2

           Build=false
           for i in "${Dependencies[@]}"
           do
               if [[ $(ls $i) == "" ]]
               then
                  Build=true
               fi
           done

           Size=$(stat --printf="%s" $LogDir/Build.out.txt)
           ExpectedSize=7537
           if [[ $Size -gt $ExpectedSize ]]
           then
               Size=$(($ExpectedSize-1))
           fi
           Percent=$(($Size*100/$ExpectedSize))
           echo $Percent
       done

       echo 100

   ) | zenity --progress $GeneralOptions --no-cancel --auto-close --text=$Building_eosio_Code

} 2> /dev/null

## If eosio wallet doesn't already exist then create it
DefaultPrivateKey=5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

if [[ $(ls $WalletDir/$Eosio.wallet) == "" ]]
then
    Return=$($CleosDir/cleos wallet create -n $Eosio) 2> $LogDir/eoshGUI.err.log
    Return=$(echo $Return  | sed 's;\(.*\)"\(.*\)"\(.*\);\2;g')
    $(echo $Return > $WalletDir/$Eosio.password)
    $CleosDir/cleos wallet import -n $Eosio --private-key $DefaultPrivateKey
fi

## If soloproducer wallet doesn't already exist then create it
if [[ $(ls $WalletDir/$ProducerName.wallet) == "" ]]
then
    Return=$($CleosDir/cleos wallet create -n $ProducerName) 2> $LogDir/eoshGUI.err.log
    Return=$(echo $Return  | sed 's;\(.*\)"\(.*\)"\(.*\);\2;g')
    $(echo $Return > $WalletDir/$ProducerName.password)
    $CleosDir/cleos wallet import -n $ProducerName --private-key $DefaultPrivateKey
fi

## Start the chain
/bin/bash ~/eosh/Local.StartChain.sh &

## Main loop
FunctionListMode=Basic
Exit=false
while [[ $Exit == false ]]
do
   ## Transaction form
   function RunTransactionForm ()
   {
        Output=$(zenity $GeneralOptions --forms --separator="|" --text="$Function" --add-entry="$Entry_Expiration_in_Seconds" --add-combo="$TransactionAccountPrompt" --combo-values="$AccountList" "${EntryList[@]}" 2> /dev/null)

        if [[ $Output != "" ]]
        then
            IFS="|" read -ra A <<< "$Output"
            TransactionAccount=${A[1]}
            TransactionName=$(echo $Function | sed "s;Transaction:;;g")
            TransactionName=$(echo $TransactionName | sed "s; ;;g")
            UnsignedTransactionFile=$TransactionName-$(date +"%s")
            FullFilePath=$TransactionDir/$UnsignedTransactionFile.unsigned
        fi
   }

   ## Input validation
   function ValidateAccountName
   {
       if [[ ! "$1" =~ ^([ \t]*)([1-5a-z\.]{1,12})([ \t]*)$ ]]
       then
           ValidInputs=false
           Display=$Display$1$Invalid_Account_Name
       fi
   }

   function ValidateNumber
   {
       if [[ ! $1 =~ ^([ \t]*)([0-9]*)([ \t]*)$ ]]
       then
           ValidInputs=false
           Display=$Display$1$Invalid_Number
       fi
   }

   function ValidateToken
   {
       if [[ ! $1 =~ ^([ \t]*)([A-Z]{1,7})([ \t]*)$ ]]
       then
           ValidInputs=false
           Display=$Display$1$Invalid_Token_Name
       fi
   }

   function ValidatePublicKey
   {
       if [[ ! $1 =~ ^([ \t]*)(EOS[a-zA-Z0-9]{50})([ \t]*)$ ]]
       then
           ValidInputs=false
           Display=$Display$1$Invalid_Public_Key
       fi
   }

   function ValidateTransactionID
   {
       if [[ ! $1 =~ ^([ \t]*)([a-zA-Z0-9]{64})([ \t]*)$ ]]
       then
           ValidInputs=false
           Display=$Display$1$Invliad_Transaction_ID
       fi
   }

   function ValidateAmount
   {
      if [[ ! $1 =~ ^([ \t]*)([0-9]{1,})(\.?)([0-9]*)([ \t]*)([A-Z]{1,7})([ \t]*)$ ]]
      then    
           ValidInputs=false
           Display=$Display$1$Invalid_Amount
      fi
   }

   function ValidateProducerList
   {
       IFS=" " read -ra Producers <<< "$1"

       for Producer in "${Producers[@]}"
       do
           ValidateAccountName "${Producer}"
       done

       if [[ ${#Producers[@]} -gt 30 ]]
       then 
           ValidInputs=false
           Display=$Display$1$Invalid_Producer_Number
       fi
   }

   function ValidateYesOrNo
   {
       if [[ $1 == "$Entry_Yes", ]]
       then
           Transfer="--transfer"
       elif [[ $1 == "$Entry_No", ]]
       then
           Transfer=""
       else
           ValidInputs=false
           Display=$Display$1$Invalid_Yes_or_No
       fi
   }

    ## Get Account List
    WalletList=$(ls $WalletDir/*.wallet)
    AccountList=$(echo $WalletList  | sed "s;$WalletDir/;;g")
    AccountList=$(echo $AccountList | sed "s;\.wallet;;g")
    AccountList=$(echo $AccountList | sed "s; ;|;g")

    ## Clear loop variables
    Display=""
    TransactionAccount=""
    UnsignedTransactionFile=""
    FullFilePath=""
    A=""
    ValidInputs=true

    ## Functions
    if [[ $FunctionListMode == Advanced ]]
    then
        FunctionList=(
            "$Local_Block_Monitor"
            "$Local_Get_Account"
            "$Local_Get_Delegated_Bandwidth"
            "$Local_Get_Balance"
            "$Local_Get_Name_Bidding_Information"
            "$Local_Get_Producers"
            "$Local_Get_Blockchain_Information"
            "$Local_Get_Block"
            "$Local_Get_Code"
            "$Local_Get_ABI"
            "$Local_Get_Currency_Stats"
            "$Local_Get_Accounts"
            "$Local_Get_Servants"
            "$Local_Get_Transaction"
            "$Local_Get_Table"
            "$Local_Get_Actions"
            "$Local_Stop_Blockchain"
            "$Local_Start_Blockchain"
            "$Local_Delete_Blockchain"
            "$Transaction_New_Account"
            "$Transaction_Transfer"
            "$Transaction_Delegate_Bandwidth"
            "$Transaction_Undelegate_Bandwidth"
            "$Transaction_Vote_for_Producers"
            "$Transaction_Vote_via_Proxy"
            "$Transaction_Buy_RAM"
            "$Transaction_Sell_RAM"
            "$Transaction_Bid_on_Name"
            "$Transaction_Register_Proxy"
            "$Transaction_Unregister_Proxy"
            "$Transaction_Register_Producer"
            "$Transaction_Unregister_Producer"
            "$Transaction_Claim_Producer_Awards"
            "$Transaction_Open_Directory"
            "$Wallet_Create_Key_Pair"
            "$Wallet_Create"
            "$Wallet_Open_Directory"
            "$System_Check_Network_Connection"
            "$System_Check_Swap_Disk"
            "$System_Check_Process_Trace"
            "$System_Check_eosio_Code"
            "$System_Shutdown"
            "$eosh_Backup"
            "$eosh_Open_Log_Directory"
            "$eosh_About"
            "$eosh_License"
            "$eosh_Basic_Mode"
            "$eosh_Donate")
    else
        FunctionList=(
            "$Local_Block_Monitor"
            "$Local_Get_Account"
            "$Local_Get_Accounts"
            "$Local_Get_Delegated_Bandwidth"
            "$Local_Get_Balance"
            "$Local_Get_Name_Bidding_Information"
            "$Local_Stop_Blockchain"
            "$Local_Start_Blockchain"
            "$Local_Delete_Blockchain"
            "$Transaction_New_Account"
            "$Transaction_Transfer"
            "$Transaction_Delegate_Bandwidth"
            "$Transaction_Undelegate_Bandwidth"
            "$Transaction_Vote_for_Producers"
            "$Transaction_Vote_via_Proxy"
            "$Transaction_Buy_RAM"
            "$Transaction_Sell_RAM"
            "$Transaction_Bid_on_Name"
            "$Transaction_Register_Proxy"
            "$Transaction_Unregister_Proxy"
            "$Transaction_Open_Directory"
            "$Wallet_Create_Key_Pair"
            "$Wallet_Create"
            "$Wallet_Open_Directory"
            "$System_Shutdown"
            "$eosh_Backup"
            "$eosh_Quick_Start_Walkthrough"
            "$eosh_About"
            "$eosh_License"
            "$eosh_Advanced_Mode"
            "$eosh_Donate")
    fi

    ## Choose Function
    Function=$(zenity $GeneralOptions --width=300 --height=480 --cancel-label="$Main_Dialog_Exit" --ok-label="$Main_Dialog_Select" --list --hide-header --column=1 --text="$Main_Dialog_Text" "${FunctionList[@]}" 2> /dev/null)

    ## Check for exit
    if [[ $? == 1 ]]
    then
        Exit=true
    fi
      
    ## Process Function
    case $Function in
    "$Local_Get_Blockchain_Information")
        Display=$($CleosDir/cleos get info 2> $LogDir/eoshGUI.err.log) 
        ;;

    "$Local_Get_Block")
        BlockNumber=$(zenity $GeneralOptions --entry --text="$Entry_Block_Number" 2> /dev/null)
        if [[ $BlockNumber != "" ]]
        then
            ValidateNumber "$BlockNumber"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get block $BlockNumber 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Producers")
        Display=$($CleosDir/cleos system listproducers 2> /dev/null)
        ;;

    "$Local_Get_Account")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get account $AccountName 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;; 

    "$Local_Get_Delegated_Bandwidth")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
               Display=$($CleosDir/cleos system listbw $AccountName 2> $LogDir/eoshGUI.err.log) 
           fi
        fi
        ;;

    "$Local_Get_Code")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get code $AccountName 2> $LogDir/eoshGUI.err.log) 
            fi
        fi
        ;;

    "$Local_Get_ABI")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get abi $AccountName 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Currency_Stats")
        Output=$(zenity $GeneralOptions --forms --separator="|" --text="$Fn8" --add-entry="$Entry_Contract" --add-entry="$Entry_Token" 2> /dev/null)
        if [[ $Output != "" ]]
        then
            IFS="|" read -ra A <<< "$Output"
            Contract=${A[0]}
            Token=${A[1]}
            ValidateAccountName "$Contract"
            ValidateToken "$Token"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get currency stats $Contract $Token 2> $LogDir/eoshGUI.err.log) 
            fi
        fi
        ;;

    "$Local_Get_Balance")
        Output=$(zenity $GeneralOptions --forms --separator="|" --text="$Fn9" --add-entry="$Entry_Contract" --add-entry="$Entry_Account_Name" --add-entry="$Entry_Token" 2> /dev/null)
        if [[ $Output != "" ]]
        then
            IFS="|" read -ra A <<< "$Output"
            Contract=${A[0]}
            AccountName=${A[1]}
            Token=${A[2]}
            ValidateAccountName "$Contract"
            ValidateAccountName "$AccountName"
            ValidateToken "$Token"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get currency balance $Contract $AccountName $Token 2> $LogDir/eoshGUI.err.log) 
                read
            fi
        fi
        ;;

    "$Local_Get_Accounts")
        PublicKey=$(zenity $GeneralOptions --entry --text="$Entry_Public_Key" 2> /dev/null)
        if [[ $PublicKey != "" ]]
        then
            ValidatePublicKey "$PublicKey"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get accounts $PublicKey 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Servants")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get servants $AccountName 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Transaction")
        TransactionID=$(zenity $GeneralOptions --entry --text="$Entry_Transaction_ID" 2> /dev/null)
        if [[ $TransactionID != "" ]]
        then
            ValidateTransactionID "$TransactionID"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get transaction $TransactionID 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Table")
        Output=$(zenity $GeneralOptions --forms --separator="|" --text="$FnD" --add-entry="$Entry_Contract" --add-entry="$Entry_Scope" --add-entry="$Entry_Table" 2> /dev/null)
        if [[ $Output != "" ]]
        then
            IFS="|" read -ra A <<< "$Output"
            Contract=${A[0]}
            Scope=${A[1]}
            Table=${A[2]}
            ValidateAccountName "$Contract"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get table $Contract $Scope $Table 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Actions")
        AccountName=$(zenity $GeneralOptions --entry --text="$Entry_Account_Name" 2> /dev/null)
        if [[ $AccountName != "" ]]
        then
            ValidateAccountName "$AccountName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos get actions $AccountName 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Get_Name_Bidding_Information")
        NewName=$(zenity $GeneralOptions --entry --text="$Entry_New_Name_Bidded_On" 2> /dev/null)
        if [[ $NewName != "" ]]
        then
            ValidateAccountName "$NewName"
            if [[ $ValidInputs == true ]]
            then
                Display=$($CleosDir/cleos system bidnameinfo $NewName 2> $LogDir/eoshGUI.err.log)
            fi
        fi
        ;;

    "$Local_Stop_Blockchain")
        kill -SIGTERM $(pgrep nodeos)
        ;;

    "$Local_Start_Blockchain")
        /bin/bash ~/eosh/Local.StartChain.sh &
        ;;

    "$Local_Block_Monitor")
        /bin/bash ~/eosh/Local.BlockMonitor.sh &
        ;;

    "$Local_Delete_Blockchain")
        Answer=$(zenity $GeneralOptions --question --text="$Dialog_Delete_Blockchain" --default-cancel --ellipsize)
        if [[ $? == "0" ]]
        then
            kill -SIGTERM $(pgrep nodeos)
            rm -rd ~/.local/share/eosio/nodeos
        fi
        ;;

    "$Transaction_New_Account")
        TransactionAccountPrompt="$Entry_Creator_Account"
        EntryList=(--add-entry="$Entry_Delegated_for_Network_Bandwidth" --add-entry="$Entry_Delegated_for_CPU_Bandwidth" --add-entry="$Entry_Kilobytes_of_RAM_to_Buy" --add-list="$Entry_Transfer_Voting_and_Delegation_Rights" --list-values="$Entry_Yes|$Entry_No" --add-combo="$Entry_New_Account_Name" --combo-values="$AccountList")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAmount "${A[2]}"
            ValidateAmount "${A[3]}"
            ValidateNumber "${A[4]}"
            ValidateYesOrNo "${A[5]}"
            ValidateAccountName "${A[6]}"

            if [[ $ValidInputs == true ]]
            then
                NewAccount=${A[6]}
                Transfer=""
                if [[ ${A[5]} == "$Entry_Yes", ]]
                then
                    Transfer="--transfer"
                fi
                PublicKey=$(~/eosh/Wallet.GetPublicKey.sh $NewAccount)
                if [[ $PublicKey != "" ]]
                then
                    $CleosDir/cleos system newaccount $Transfer -x ${A[0]} --stake-net "${A[2]}" --stake-cpu "${A[3]}" --buy-ram-kbytes ${A[4]} -sdj $TransactionAccount $NewAccount $PublicKey > $FullFilePath 2> $LogDir/eoshGUI.err.log
                else
                   Display=$(echo "$Dialog_Failed_to_Retrieve_Public_Key "$NewAccountName"$Dialog_Does_the_Password_Unlock_the_Wallet")
                fi
            fi
        fi
        ;;

    "$Transaction_Register_Producer")
        TransactionAccountPrompt="$Entry_Block_Producer_Account"
        EntryList=(--add-entry="$Entry_URL" --add-entry="$Entry_Location")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            if [[ $ValidInputs == true ]]
            then
                PublicKey=$(~/eosh/Wallet.GetPublicKey.sh $TransactionAccount)
                if [[ $PublicKey != "" ]]
                then
                    $CleosDir/cleos system regproducer -sdj -x ${A[0]} $TransactionAccount $PublicKey ${A[2]} ${A[3]} > $FullFilePath 2> $LogDir/eoshGUI.err.log
                else
                   Display=$(echo "$Dialog_Failed_to_Retrieve_Public_Key "$TransactionAccount"$Dialog_Does_the_Password_Unlock_the_Wallet")
                fi
            fi
        fi
        ;;

    "$Transaction_Unregister_Producer")
        TransactionAccountPrompt="$Entry_Block_Producer_Account"
        EntryList=()
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system unregprod -sdj -x ${A[0]} $TransactionAccount > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Vote_for_Producers")
        TransactionAccountPrompt="$Entry_Voting_Account"
        EntryList=( --add-entry="$Entry_Producer_Names" )
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateProducerList "${A[2]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system voteproducer prods -sdj -x ${A[0]} $TransactionAccount ${A[2]} > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Vote_via_Proxy")
        TransactionAccountPrompt="$Entry_Voting_Account"
        EntryList=( --add-entry="$Entry_Proxy_Name" )
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system voteproducer proxy -sdj -x ${A[0]} $TransactionAccount ${A[2]} > $FullFilePath 2> $LogDir/eoshGUI.err.log 
            fi
        fi
        ;;

    "$Transaction_Delegate_Bandwidth")
        TransactionAccountPrompt="$Entry_Account_to_Delegate_From"
        EntryList=(--add-entry="$Entry_Account_to_Delegate_To" --add-entry="$Entry_Account_to_Delegate_for_Network" --add-entry="$Entry_Account_to_Delegate_for_CPU")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            ValidateAmount "${A[3]}"
            ValidateAmount "${A[4]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system delegatebw -sdj -x ${A[0]} $TransactionAccount ${A[2]} "${A[3]}" "${A[4]}" > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Undelegate_Bandwidth")
        TransactionAccountPrompt="$Entry_Account_Undelegating"
        EntryList=(--add-entry="$Entry_Account_to_Undelegate_From" --add-entry="$Entry_Account_to_Undelegate_for_Network" --add-entry="$Entry_Account_to_Undelegate_for_CPU")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            ValidateAmount "${A[3]}"
            ValidateAmount "${A[4]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system undelegatebw -sdj -x ${A[0]} $TransactionAccount ${A[2]} "${A[3]}" "${A[4]}" > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Bid_on_Name")
        TransactionAccountPrompt="$Entry_Bidding_Account"
        EntryList=(--add-entry="$Entry_Name_to_Bid_On" --add-entry="$Entry_Ammount_to_Bid")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            ValidateAmount "${A[3]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system bidname -sdj -x ${A[0]} $TransactionAccount ${A[2]} "${A[3]}" > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Buy_RAM")
        TransactionAccountPrompt="$Entry_Buyer_Account"
        EntryList=(--add-entry="$Entry_Receiver_Account" --add-entry="$Entry_Amount_to_pay")
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            ValidateAmount "${A[3]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system buyram -sdj -x ${A[0]} $TransactionAccount ${A[2]} "${A[3]}" > $FullFilePath 2> $LogDir/eoshGUI.err.log 
            fi
        fi
        ;;

    "$Transaction_Sell_RAM")
        TransactionAccountPrompt="$Entry_Seller_Account"
        EntryList=( --add-entry="$Entry_Bytes_to_Sell" )
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            ValidateNumber "${A[2]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system sellram -sdj -x ${A[0]} $TransactionAccount ${A[2]} > $FullFilePath 2> $LogDir/eoshGUI.err.log 
            fi
        fi
        ;;

    "$Transaction_Claim_Producer_Awards")
        TransactionAccountPrompt="$Entry_Block_Producer_Account"
        EntryList=()
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system claimrewards -sdj -x ${A[0]} $TransactionAccount > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Register_Proxy")
        TransactionAccountPrompt="$Entry_Proxy_Name"
        EntryList=()
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system regproxy -sdj -x ${A[0]} $TransactionAccount > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Unregister_Proxy")
        TransactionAccountPrompt="$Entry_Proxy_Name"
        EntryList=()
        RunTransactionForm
        if [[ $A != "" ]]
        then
            ValidateNumber "${A[0]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos system unregproxy -sdj -x ${A[0]} $TransactionAccount > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Transfer")
        TransactionAccountPrompt="$Entry_Transfer_from_Account"
        EntryList=(--add-entry="$Entry_Transfer_to_Account" --add-entry="$Entry_Amount_to_Transfer" --add-entry="$Entry_Memo")
        RunTransactionForm
        if [[ $A != "" ]]
            then
            ValidateNumber "${A[0]}"
            ValidateAccountName "${A[2]}"
            ValidateAmount "${A[3]}"
            if [[ $ValidInputs == true ]]
            then
                $CleosDir/cleos transfer -sdj -x ${A[0]} $TransactionAccount ${A[2]} "${A[3]}" "${A[4]}" > $FullFilePath 2> $LogDir/eoshGUI.err.log
            fi
        fi
        ;;

    "$Transaction_Open_Directory")
        xdg-open $TransactionDir
        ;;

    "$Wallet_Create")
        NewAccountName=$(zenity $GeneralOptions --entry --text="$Entry_New_Account_Name" 2> /dev/null)
        if [[ $NewAccountName != "" ]]
        then
            ValidateAccountName "$NewAccountName"
            if [[ $ValidInputs == true ]]
            then
                ~/eosh/Wallet.Create.sh $NewAccountName
            fi
        fi
        ;; 

    "$Wallet_Create_Key_Pair")
        ~/eosh/Wallet.CreateKeyPair.sh
        ;;

    "$Wallet_Open_Directory")
        xdg-open $WalletDir
        ;;

    "$System_Check_Network_Connection")
        Display=$(ifconfig)
        ;;

    "$System_Check_Swap_Disk")
        Display=$(free -m)
        ;;

    "$System_Check_Process_Trace")
        $(strace -p $$ 2> $LogDir/strace.err)
        Display=$(cat $LogDir/strace.err)
        ;;

    "$System_Check_eosio_Code")
        $(gnome-terminal -- ~/eosh/System.TestEosioCode.sh)
        ;;

    "$System_Shutdown")
        Output=$(zenity $GeneralOptions --forms --separator="|" --text="$Function" --add-combo="$Dialog_Power_Mode" --combo-values="$Dialog_Power_Off|$Dialog_Reboot" --add-combo="$Dialog_Erase_RAM_Mode" --combo-values="$Dialog_Fast|$Dialog_Secure" 2> /dev/null)
	if [[ $Output != "" ]]
        then
            IFS="|" read -ra A <<< "$Output"
            if [[ ${A[0]} == "$Dialog_Reboot" ]]
            then
                if [[ ${A[1]} == "$Dialog_Fast" ]]
                then
                    $(gnome-terminal -- ~/eosh/System.Shutdown.sh reboot fast)
                else
                    $(gnome-terminal -- ~/eosh/System.Shutdown.sh reboot)
                fi
            else
                if [[ ${A[1]} == "$Dialog_Fast" ]]
                then
                    $(gnome-terminal -- ~/eosh/System.Shutdown.sh fast)
                else
                    $(gnome-terminal -- ~/eosh/System.Shutdown.sh)
                fi
            fi
            Exit=true
        fi
        ;;

    "$eosh_Backup")
        Filename=$BackupDir/$(date +"%s").tar
        tar rvf $Filename $WalletDir
        tar rvf $Filename --exclude=backup --exclude=logs --exclude=transactions ~/eosh 
        xdg-open $BackupDir
        ;;

    "$eosh_Open_Log_Directory")
        xdg-open $LogDir
        ;;

    "$eosh_Quick_Start_Walkthrough")
        gedit ~/eosh/docs/QuickStartWalkthrough.txt &
        ;;

    "$eosh_About")
        Display=$(cat ~/eosh/docs/About.txt);
        ;;

    "$eosh_License")
        Display=$(cat ~/eosh/docs/License.txt);
        ;;

    "$eosh_Advanced_Mode")
        FunctionListMode=Advanced
        ;;

    "$eosh_Basic_Mode")
        FunctionListMode=Basic
        ;;

    "$eosh_Donate")
        Display=$(cat ~/eosh/docs/Donate.txt);
        ;;

    "")
        ;;

    esac

    ## Display result
    if [[ $Display != "" ]]
    then
        echo "$Display" > $LogDir/Display.txt
        zenity $GeneralOptions --width=640 --height=480 --text-info --no-interaction --font=11 --filename=logs/Display.txt 2> /dev/null
    fi

    ## Process Transaction
    if [[ $FullFilePath != "" ]]
    then
        File=$(cat $FullFilePath)

	if [[ $File == "" ]]
	then 
            if [[ $(pidof nodeos) == "" ]]
            then
                zenity $GeneralOptions --ellipsize --info --no-markup --text="$Dialog_Chain_Not_Running" 2> /dev/null 
            else
                zenity $GeneralOptions --ellipsize --info --no-markup --text="$Dialog_Transaction_Failed" 2> /dev/null
            fi
        else
            zenity $GeneralOptions --ellipsize --info --no-markup --text="$(cat $FullFilePath)" 2> /dev/null

            ## Process the transaction file
            if [[ $UnsignedTransactionFile != "" ]]
            then
                Chain=$(zenity $GeneralOptions --list --hide-header --column=1 --text="$Dialog_Select_Chain_to_Broadcast_On" "$Dialog_Local" "$Dialog_Mainnet" 2> /dev/null)
                case $Chain in
                "$Dialog_Local")

                ~/eosh/Transaction.Process.sh $TransactionAccount $UnsignedTransactionFile local
                ;;
                "$Dialog_Mainnet")
                   RefBlockData=$(zenity $GeneralOptions --forms --separator=" " --text="$Dialog_Mainnet_Reference_Block" --add-entry="ref_block_num" --add-entry="ref_block_prefix") 2> /dev/null
                   ~/eosh/Transaction.Process.sh $TransactionAccount $UnsignedTransactionFile mainnet $RefBlockData
               ;;
               esac
          fi
       fi
   fi
done

kill -SIGTERM $(pgrep nodeos)

exit 0
