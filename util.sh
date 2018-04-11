
function getUnspent () {
    $ECHO " == Getting UTXOs"
    ALL_UTXOS=`$CLI  listunspent | jq ".|=sort_by(.amount)|reverse|.[0:$COUNT]"`

    if [ $ALL_UTXOS == "[]" ] ; then
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

echo "Util done!"
