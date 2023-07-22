#!/bin/bash

ZFS_NODE="new-pool/pruned"
ZFS_POOL="new-pool/prunedSnapshot"
NAS_LOCATION="/pokt-snap/public/pruned"
NUMBER_OF_SNAPS_TO_KEEP=3
POKT_PORT=26637
POKT_BLOCK=""
POKT_PRUNE_BLOCK=""
PRUNE_FROM_TIP=500
DATE=""

function grabDate() {
    DATE=$(date +%F)
    echo "DATE: $DATE"
}

function grabPoktBlock() {
    POKT_BLOCK=$(curl -s "http://localhost:$POKT_PORT/status" | jq '.result.sync_info.latest_block_height' | tr -d '"')
    echo "BLOCK: $POKT_BLOCK"
}

function prunedBlock() {
    POKT_PRUNE_BLOCK="$((POKT_BLOCK-PRUNE_FROM_TIP))"
}

function takeZFSSnap() {
    echo "deleting old snap"
    zfs destroy "$ZFS_POOL"
    echo "creating new clone"
    zfs snapshot "$ZFS_NODE@prunesnap$DATE"
    zfs clone "$ZFS_NODE@prunesnap$DATE" "$ZFS_POOL"
    echo "data DIR cloned too $ZFS_POOL"
}

function createTars() {
    echo "creating tar on data dir"
    echo "$POKT_BLOCK"
    echo "$NAS_LOCATION/$POKT_BLOCK-$DATE.tar.lz4"
    cd "/$ZFS_POOL/.pocket"
    tar -cf - "data/" | lz4 > "$NAS_LOCATION/pruned-$POKT_PRUNE_BLOCK-$POKT_BLOCK-$DATE.tar.lz4"
    echo "pruned-$POKT_PRUNE_BLOCK-$POKT_BLOCK-$DATE.tar.lz4" > $NAS_LOCATION/latest_compressed.txt
    echo "created a compressed data dir"
    tar -cf "$NAS_LOCATION/pruned-$POKT_PRUNE_BLOCK-$POKT_BLOCK-$DATE.tar" "data/"
    echo "pruned-$POKT_PRUNE_BLOCK-$POKT_BLOCK-$DATE.tar" > $NAS_LOCATION/latest.txt
    echo "created a uncompressed data dir"
}

function prune() {
    prunedBlock
    cd "/$ZFS_POOL/.pocket"
    pruner "$POKT_PRUNE_BLOCK" data application,blockstore,txindexer

    pruner_result=$?
    if [ $pruner_result -ne 0 ];
    then
        echo "pruner failed!"
        [ -d data/application-new.db ] && rm -rf data/application-new.db
        [ -d data/blockstore-new.db ] && rm -rf data/blockstore-new.db
        [ -d data/txindexer-new.db ] && rm -rf data/txindexer-new.db
        return
    fi

    rm -rf data/application.db
    mv data/application-new.db data/application.db
    rm -rf data/blockstore.db
    mv data/blockstore-new.db data/blockstore.db
    rm -rf data/txindexer.db
    mv data/txindexer-new.db data/txindexer.db
}

function removeOld() {
    compressedFiles=$(ls -t $NAS_LOCATION/*.tar.lz4)
    numberOfCompressed=$(echo "$compressedFiles" | wc -l)
    if [ "$numberOfCompressed" -gt "$NUMBER_OF_SNAPS_TO_KEEP" ]; then
        fileToDelete=$(echo "$compressedFiles" | tail -n1)
        rm "$fileToDelete"
    fi

    uncompressedFiles=$(ls -t $NAS_LOCATION/*.tar)
    numberOfUnCompressed=$(echo "$uncompressedFiles" | wc -l)
    if (( numberOfUnCompressed > NUMBER_OF_SNAPS_TO_KEEP )); then
        fileToDelete=$(echo "$uncompressedFiles" | tail -n1)
        rm "$fileToDelete"
    fi
}

grabDate
grabPoktBlock
takeZFSSnap
prune
createTars
removeOld