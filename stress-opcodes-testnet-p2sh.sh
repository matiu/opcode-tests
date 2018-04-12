#!/bin/bash

CLI="$HOME/dev/bitcoin-abc/build/src/bitcoin-cli -testnet "
CLITX="$HOME/dev/bitcoin-abc/build/src/bitcoin-tx -testnet "

# 200 bytes op_return
#SCRIPT="OP_RETURN \
#0x0102030405060708090001020304050607080900010203040506070809000102030405060708090001020304050607080900\
#0102030405060708090001020304050607080900010203040506070809000102030405060708090001020304050607080900\
#0102030405060708090001020304050607080900010203040506070809000102030405060708090001020304050607080900\
#0102030405060708090001020304050607080900010203040506070809000102030405060708090001020304050607080900"

SCRIPT='0 BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM BIN2NUM 0 EQUAL'
#SCRIPT='1 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR 1 XOR'
#SCRIPT='1'
FEE=0.0001

## 
COUNT=1  ## Only 1 for p2sh
OUTPUTSPERTX=1  ## Only 1 for p2sh
SH=':S'


ECHO="echo "
ADDR=`$CLI getnewaddress|cut -d ":" -f 2`

source ./util.sh

$ECHO "TEST CASE DESCRIPTON (TESTNET)"
$ECHO "  Script:$SCRIPT "
$ECHO "  (nr opcodes):`echo $SCRIPT | wc -w`"
$ECHO "  NR OF TXs: $COUNT"
$ECHO "  NR OF OUTPUTS PER TXs: $OUTPUTSPERTX"

function createSpendTxs () {
  $ECHO " == Creating Spend TXs (Redeem script)"
    for TXIDVALUE in $TXIDS ; do
        TXID=`echo $TXIDVALUE| cut -d "|" -f 1`;
        V=`echo $TXIDVALUE| cut -d "|" -f 2`;
        VALUE=`echo $V \* $OUTPUTSPERTX- $FEE | bc -l`


        ## grab hex scriptpubkey from sent TX
        SCRIPTPUBKEY=`$CLI getrawtransaction $TXID 1|jq .vout[0].scriptPubKey.hex | sed -e 's/^"//' -e 's/"$//'`;
        echo $SCRIPTPUBKEY;

        ## create a dummy tx just to encode the script in hex
        TXCMD2="$CLITX -create outscript=0.1:\"$SCRIPT\""
        SCRIPTTX=`eval $TXCMD2`;
        REDDEMSCRIPT=`$CLI decoderawtransaction $SCRIPTTX|jq .vout[0].scriptPubKey.hex| sed -e 's/^"//' -e 's/"$//'`;

        COUNTER=0
        TXCMD="$CLITX -create"
        while [  $COUNTER -lt $OUTPUTSPERTX ]; do
            TXCMD="$TXCMD  in=$TXID:$COUNTER "
          let COUNTER=COUNTER+1 
        done

        TXCMD="$TXCMD outaddr=$VALUE:$ADDR"

        # redeem script part

        # dummy privatekey
        TXCMD="$TXCMD set=\"privatekeys\":'[\"cRAGqiCxff6mT4oE9pyJ4NMGjMEhhDu4VEH3to2N9q3R1xKvmHqQ\"]'" 
        TXCMD="$TXCMD set=\"prevtxs\":'[{\"txid\":\"$TXID\", \"vout\":0, \"scriptPubKey\": \"$SCRIPTPUBKEY\", \"redeemScript\":\"$REDDEMSCRIPT\", \"amount\":$V }]'"
        TXCMD="$TXCMD sign=\"ALL\""

        TX1=`eval $TXCMD`

        if [ -z "$TX1" ] ; then
            echo "!! Could not create tx with $TXCMD"
            exit 1
        fi


        STXS="$STXS $TX1"
    done
}

if [ -z "$UNSPENT" ]
then
    getUnspent 
fi
createTxs 
sendTxs 

#TXIDS='46ba125b87b3be69fcaeabd0965422b7a9097192da571d2f2d8b645d1e73011e|12.99830000'
createSpendTxs
sendSpendTxs 
$ECHO "  "
$ECHO "  ## After everything is confirmed, funds should be back at $ADDR"




