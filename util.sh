
function getUnspent () {
    $ECHO " == Getting UTXOs"
    ALL_UTXOS=`$CLI  listunspent | jq ".|=sort_by(.amount)|reverse|.[0:$COUNT]"`

    if [ $ALL_UTXOS == '[]' ] ; then
        echo "!! NO UTXOs"
        exit 1
    fi

    COUNTER=0
    while [  $COUNTER -lt $COUNT ]; do
        INDEX=$((1+COUNTER))
        UTXO=`echo $ALL_UTXOS| jq ".[-$INDEX]"`
        OUTPOINT=`echo $UTXO | jq .txid | sed -e 's/^"//' -e 's/"$//'`:0
        VALUE=`echo $UTXO | jq .amount | sed -e 's/^"//' -e 's/"$//'`

        UNSPENT="$UNSPENT $OUTPOINT|$VALUE"

        let COUNTER=COUNTER+1 
    done
}

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
        if [ -z "$TX1" ] ; then
            echo "!! Could not create tx"
            exit 1
        fi


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



