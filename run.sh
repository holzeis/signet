#!/bin/sh
set -e
set -m

datadir=/data
if [ ! -z "$1" ]; then 
    datadir=$1
fi

if [ ! -d "$datadir" ]; then
    mkdir -p $datadir
fi

rsync -ru /root/.bitcoin/* $datadir

bitcoind -datadir=$datadir -wallet="faucet" -reindex &
printf "Waiting for custom Signet bitcoind to start\n"
sleep 2

NBITS=1d1cf84c

NADDR=$(bitcoin-cli -datadir=$datadir getnewaddress)

./bitcoin/contrib/signet/miner --cli="bitcoin-cli -datadir=$datadir" generate --address $NADDR --grind-cmd="bitcoin-util grind" --nbits=$NBITS --set-block-time=$(date +%s)
./bitcoin/contrib/signet/miner --cli="bitcoin-cli -datadir=$datadir" generate --address $NADDR --grind-cmd="bitcoin-util grind" --nbits=$NBITS --ongoing &

fg %1