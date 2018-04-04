#!/bin/bash

CLI="$HOME/dev/bitcoin-abc/build/src/bitcoin-cli -regtest "
CLITX="$HOME/dev/bitcoin-abc/build/src/bitcoin-tx -regtest "
SCRIPT='1 1 XOR 1 XOR 1 XOR 1 XOR'
FEE=0.0001
COUNT=100

ECHO="echo "



$CLI generate 100 >/dev/null || exit

function setUnspent () {
    UNSPENT=`$CLI  listunspent | jq '.|=sort_by(.amount)|.[-1]'`
    OUTPOINT=`echo $UNSPENT | jq .txid | sed -e 's/^"//' -e 's/"$//'`:0
    VALUE=`echo $UNSPENT | jq .amount | sed -e 's/^"//' -e 's/"$//'`
    VALUE=`echo $VALUE - $FEE | bc`
}

function createTx () {
    $ECHO ""
    $ECHO "## Creating TX:"
    $ECHO "  Value:$VALUE"
    $ECHO "  Script:$SCRIPT"
    $ECHO "  UTXO: $OUTPOINT"
    TX1=`$CLITX -create in=$OUTPOINT outscript=$VALUE:"$SCRIPT"`
    TX=`$CLI signrawtransaction $TX1| jq .hex  | sed -e 's/^"//' -e 's/"$//'`
}


function sendTx () {
    TXID=`$CLI sendrawtransaction $TX`
}


COUNTER=0
while [  $COUNTER -lt $COUNT ]; do
    setUnspent
    createTx
    #echo $TX
    #$CLI decoderawtransaction $TX

    sendTx
    echo "  => $TXID"

    #spend it

    VALUE=`echo $VALUE - $FEE | bc`
    TX=`$CLITX -create in=$TXID:0 outscript=$VALUE:"$SCRIPT"`
    sendTx
    $ECHO "    ^ SPENT AT:$TXID"


    let COUNTER=COUNTER+1 
done




