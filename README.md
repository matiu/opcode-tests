
bitcoin-abc new opcodes stress test

Run bitcoind with:
`~/dev/bitcoin-abc/build/src/bitcoind -regtest  -monolithactivationtime=0`
or
`~/dev/bitcoin-abc/build/src/bitcoind -testnet  -monolithactivationtime=XXXXXXXXX`

then:
./stress-opcodes.sh
or
./stress-opcodes-testnet.sh

 * change "SCRIPT" to evaluate other OP_CODES
 * tx creation in based on https://gist.github.com/matiu/f7b4afb3781c9f7c735435f19602db31
 * if you dont have available uxtos in regtest, run the script one and interrupt it after "mining" to get matured utxos for the next run



