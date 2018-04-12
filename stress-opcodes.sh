#!/bin/bash

CLI="$HOME/dev/bitcoin-abc/build/src/bitcoin-cli -regtest "
CLITX="$HOME/dev/bitcoin-abc/build/src/bitcoin-tx -regtest "
SCRIPT='0 BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM 0 EQUAL'
#SCRIPT='1 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR'
#SCRIPT='
#SCRIPT='1'
FEE=0.0001
COUNT=100
OUTPUTSPERTX=100

ECHO="echo "


$ECHO "TEST CASE DESCRIPTON"
$ECHO "  Script:$SCRIPT"
$ECHO "  (nr opcodes):`echo $SCRIPT | wc -w`"
$ECHO "  NR OF TXs: $COUNT"
$ECHO "  NR OF OUTPUTS PER TXs: $OUTPUTSPERTX"

$ECHO " == Mining"
$CLI generate $COUNT >/dev/null || exit

source ./util.sh

function createSpendTxs () {
    $ECHO " == Creating Spend TXs"
    for TXIDVALUE in $TXIDS ; do
        TXID=`echo $TXIDVALUE| cut -d "|" -f 1`;
        V=`echo $TXIDVALUE| cut -d "|" -f 2`;
        VALUE=`echo $V - $FEE | bc`

        COUNTER=0
        TXCMD="$CLITX -create"
        while [  $COUNTER -lt $OUTPUTSPERTX ]; do
            TXCMD="$TXCMD  in=$TXID:$COUNTER"
          let COUNTER=COUNTER+1 
        done

        TXCMD="$TXCMD outscript=$VALUE:\"$SCRIPT\""
        TX1=`eval $TXCMD`
 

       STXS="$STXS $TX"
    done
}

getUnspent
createTxs
time sendTxs

createSpendTxs
time sendSpendTxs




