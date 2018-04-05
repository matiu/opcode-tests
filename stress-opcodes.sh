#!/bin/bash

CLI="$HOME/dev/bitcoin-abc/build/src/bitcoin-cli -regtest "
CLITX="$HOME/dev/bitcoin-abc/build/src/bitcoin-tx -regtest "
SCRIPT='0 BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM 0 EQUAL'
SCRIPT='1 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR'
#SCRIPT='
#SCRIPT='1'
FEE=0.0001
COUNT=500
OUTPUTSPERTX=100

ECHO="echo "


$ECHO "TEST CASE DESCRIPTON"
$ECHO "  Script:$SCRIPT"
$ECHO "  (nr opcodes):`echo $SCRIPT | wc -w`"
$ECHO "  NR OF TXs: $COUNT"
$ECHO "  NR OF OUTPUTS PER TXs: $OUTPUTSPERTX"

$ECHO " == Mining"
$CLI generate $COUNT >/dev/null || exit

function getUnspent () {
    $ECHO " == Getting UTXOs"
    ALL_UTXOS=`$CLI  listunspent | jq ".|=sort_by(.amount)|reverse|.[0:$COUNT]"`

    COUNTER=0
    while [  $COUNTER -lt $COUNT ]; do
        INDEX=$((1+COUNTER))
        UTXO=`echo $ALL_UTXOS| jq ".[-$INDEX]"`
        OUTPOINT=`echo $UTXO | jq .txid | sed -e 's/^"//' -e 's/"$//'`:0
        VALUE=`echo $UTXO | jq .amount | sed -e 's/^"//' -e 's/"$//'`
        VALUE=`echo $VALUE - $FEE | bc`

        UNSPENT="$UNSPENT $OUTPOINT|$VALUE"

        let COUNTER=COUNTER+1 
    done
}

function createTxs () {
    $ECHO " == Creating TXs"
    for UTXO in $UNSPENT; do
        O=`echo $UTXO| cut -d "|" -f 1`;
        V=`echo $UTXO| cut -d "|" -f 2`;

        TX1=`$CLITX -create in=$O outscript=$V:"$SCRIPT"`
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

        VALUE=`echo "($V - $FEE)/$OUTPUTSPERTX" | bc -l`
        VALUE=`printf %.8f $VALUE`

        COUNTER=0
        TXCMD="$CLITX -create in=$TXID:0 "
        while [  $COUNTER -lt $OUTPUTSPERTX ]; do
          TXCMD="$TXCMD outscript=$VALUE:\"$SCRIPT\""
          let COUNTER=COUNTER+1 
        done
        TX=`eval $TXCMD`

        D=`echo $TX |wc -c`
        LENGTH=`echo $D/2 | bc`
        STXS="$STXS $TX"
    done
}

function sendSpendTxs () {
    $ECHO " ## Sending Spend TXs, USING <SCRIPT> ## TX length:$LENGTH b"
    for TX in $STXS; do
        TXID=`$CLI sendrawtransaction $TX`
    done
}

getUnspent
createTxs
time sendTxs

createSpendTxs
time sendSpendTxs




