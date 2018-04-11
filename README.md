
bitcoin-abc new opcodes stress test

Run bitcoind with:
`~/dev/bitcoin-abc/build/src/bitcoind -regtest  -monolithactivationtime=0`

then:
./stress-opcodes.sh

 * change "SCRIPT" to evaluate other OP_CODES
 * tx creation in based on https://gist.github.com/matiu/f7b4afb3781c9f7c735435f19602db31
 * if you dont have available uxtos, run the script one and interrupt it after "mining" to get matured utxos for the next run



example output:
```
## Creating TX:
  Value:24.9999
  Script:1 1 XOR 1 XOR 1 XOR 1 XOR
  UTXO: 210a41543c0a52ad41b4d9be2ce81629ebac484347c7d510edc8ac6a6206a264:0
  => 8f0f11d901b11370e0fedb8a185a52d9154e42b051bf504809f2aceb5a73097e
    ^ SPENT AT:201beb9772a87e6cb6d79606ee71ef1b86d2fe8afd2ac113cf63e433015142c3

## Creating TX:
  Value:24.9999
  Script:1 1 XOR 1 XOR 1 XOR 1 XOR
  UTXO: 8651ea35c70e8f6cae2a2985df31274ce6c16b88113694fee1ac64921bda6858:0
  => efa32d78a45e731cbccbeb5ef8db07072b83257904f0123f2721284a873967cb
    ^ SPENT AT:fcbd1673451321b6210b51f065a3515cd27272e274d8f76947f645a6ac41d339
[...]
```
