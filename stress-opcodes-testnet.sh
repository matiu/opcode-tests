#!/bin/bash

CLI="$HOME/dev/bitcoin-abc/build/src/bitcoin-cli -testnet "
CLITX="$HOME/dev/bitcoin-abc/build/src/bitcoin-tx -testnet "
SCRIPT='0 BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM 0 EQUAL'
#SCRIPT='1 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR'
#SCRIPT='
#SCRIPT='1'
FEE=0.0001
COUNT=1
OUTPUTSPERTX=100


ECHO="echo "
ADDR=`$CLI getnewaddress|cut -d ":" -f 2`

source ./util.sh

$ECHO "TEST CASE DESCRIPTON"
$ECHO "  Script:$SCRIPT TESTNET"
$ECHO "  (nr opcodes):`echo $SCRIPT | wc -w`"
$ECHO "  NR OF TXs: $COUNT"
$ECHO "  NR OF OUTPUTS PER TXs: $OUTPUTSPERTX"

function createTxs () {
    $ECHO " == Creating TXs"
    for UTXO in $UNSPENT; do
        O=`echo $UTXO| cut -d "|" -f 1`;
        V=`echo $UTXO| cut -d "|" -f 2`;

        VALUE=`echo "($V - $FEE)/$OUTPUTSPERTX" | bc -l`
        VALUE=`printf %.8f $VALUE`

        COUNTER=0
        TXCMD="$CLITX -create in=$O"
        while [  $COUNTER -lt $OUTPUTSPERTX ]; do
          TXCMD="$TXCMD outscript=$VALUE:\"$SCRIPT\""
          let COUNTER=COUNTER+1 
        done

        TX1=`eval $TXCMD`
        TX=`$CLI signrawtransaction $TX1| jq .hex  | sed -e 's/^"//' -e 's/"$//'`

        TXS="$TXS $TX|$V"
    done
}

function sendTxs () {
    $ECHO " == Sending TXs"
    for TXVALUE in $TXS; do
        TX=`echo $TXVALUE| cut -d "|" -f 1`;
        V=`echo $TXVALUE| cut -d "|" -f 2`;

        TXID=`$CLI sendrawtransaction $TX`
        TXIDS="$TXIDS $TXID|$V"
    done
}


function createSpendTxs () {
    $ECHO " == Creating Spend TXs"
    for TXIDVALUE in $TXIDS ; do
        TXID=`echo $TXIDVALUE| cut -d "|" -f 1`;
        V=`echo $TXIDVALUE| cut -d "|" -f 2`;
        VALUE=`echo $V \* $OUTPUTSPERTX- $FEE | bc -l`

        COUNTER=0
        TXCMD="$CLITX -create"
        while [  $COUNTER -lt $OUTPUTSPERTX ]; do
            TXCMD="$TXCMD  in=$TXID:$COUNTER"
          let COUNTER=COUNTER+1 
        done

        TXCMD="$TXCMD outaddr=$VALUE:$ADDR"

        TX1=`eval $TXCMD`
        STXS="$STXS $TX1"
    done
}

function sendSpendTxs () {
    $ECHO " ## Sending Spend TXs, USING <SCRIPT> ## TX"


    for TX in $STXS; do
        TXID=`$CLI sendrawtransaction $TX`
    done
}

getUnspent 
createTxs 
time sendTxs && \
createSpendTxs && \
time sendSpendTxs && \
$ECHO "  After everything is confirmed, funds should be back at $ADDR"




