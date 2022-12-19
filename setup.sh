#!/bin/sh
set -e

bitcoind -regtest -daemon -wallet="test"
printf "Waiting for regtest bitcoind to start"
sleep 2

bitcoin-cli -regtest createwallet "test"

ADDR=$(bitcoin-cli -regtest getnewaddress '' bech32)
PRIVKEY=$(bitcoin-cli -regtest dumpprivkey $ADDR)
PUBKEY=$(bitcoin-cli -regtest getaddressinfo $ADDR | jq -r .pubkey)

LENX2=$(printf $PUBKEY | wc -c)
LEN=$((LENX2/2))
LENHEX=$(echo "obase=16; $LEN" | bc)
SCRIPT=$(echo 51${LENHEX}${PUBKEY}51ae)


cat <<EOF
ADDR=$ADDR
PRIVKEY=$PRIVKEY
PUBKEY=$PUBKEY
SCRIPT=$SCRIPT
EOF

bitcoin-cli -regtest stop 2>&1

cat > /root/.bitcoin/bitcoin.conf <<EOF
signet=1

[signet]
port=38333
rpcport=38332

server=1
txindex=1

rpcuser=admin1
rpcpassword=123
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0
fallbackfee=0.00001

zmqpubrawblock=tcp://0.0.0.0:48332
zmqpubrawtx=tcp://0.0.0.0:48333

blockfilterindex=1
peerblockfilters=1

signetchallenge=$SCRIPT
EOF

bitcoind -wallet="faucet" &
printf "Waiting for custom Signet bitcoind to start"
sleep 2

bitcoin-cli createwallet "faucet"
bitcoin-cli importprivkey $PRIVKEY "faucet"

NBITS=$(./bitcoin/contrib/signet/miner --cli="bitcoin-cli" calibrate --grind-cmd="bitcoin-util grind" --seconds=20 | awk '{print $1}' | sed 's/nbits=//g')
NADDR=$(bitcoin-cli getnewaddress)

./bitcoin/contrib/signet/miner --cli="bitcoin-cli" generate --address $NADDR --grind-cmd="bitcoin-util grind" --nbits=$NBITS --max-blocks 100
printf "Stopping custom Signet bitcoind"
bitcoin-cli stop

# give the bitcoind time to properly shutdown and write blocks in memory to disk
sleep 5