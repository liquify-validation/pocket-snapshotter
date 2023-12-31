#!/bin/bash

ZFS_NODE="new-pool/node1"
ZFS_POOL="new-pool/snapshot"
NAS_LOCATION="/pokt-snap/public"
NUMBER_OF_SNAPS_TO_KEEP=3
POKT_PORT=26637
POKT_BLOCK=""
DATE=""

function grabDate() {
    DATE=$(date +%F)
    echo "DATE: $DATE"
}

function grabPoktBlock() {
    POKT_BLOCK=$(curl -s "http://localhost:$POKT_PORT/status" | jq '.result.sync_info.latest_block_height' | tr -d '"')
    echo "BLOCK: $POKT_BLOCK"
}

function takeZFSSnap() {
    echo "deleting old snap"
    zfs destroy "$ZFS_POOL"
    echo "creating new clone"
    zfs snapshot "$ZFS_NODE@snap$DATE"
    zfs clone "$ZFS_NODE@snap$DATE" "$ZFS_POOL"
    echo "data DIR cloned too $ZFS_POOL"
}

function createTars() {
    echo "creating tar on data dir"
    echo "$POKT_BLOCK"
    echo "$NAS_LOCATION/$POKT_BLOCK-$DATE.tar.lz4"
    tar -cf - "/$ZFS_POOL/.pocket/data/" | lz4 > "$NAS_LOCATION/$POKT_BLOCK-$DATE.tar.lz4"
    echo "$POKT_BLOCK-$DATE.tar.lz4" > $NAS_LOCATION/latest_compressed.txt
    echo "created a compressed data dir"
    tar -cf "$NAS_LOCATION/$POKT_BLOCK-$DATE.tar" "/$ZFS_POOL/.pocket/data/"
    echo "$POKT_BLOCK-$DATE.tar" > $NAS_LOCATION/latest.txt
    echo "created a uncompressed data dir"
}

function removeOld() {
    compressedFiles=$(ls -t $NAS_LOCATION/*.tar.lz4)
    numberOfCompressed=$(echo "$compressedFiles" | wc -l)
    if [ "$numberOfCompressed" -gt "$NUMBER_OF_SNAPS_TO_KEEP" ]; then
        fileToDelete=$(echo "$compressedFiles" | tail -n1)
        rm "$NAS_LOCATION/$fileToDelete"
    fi

    uncompressedFiles=$(ls -t $NAS_LOCATION/*.tar)
    numberOfUnCompressed=$(echo "$uncompressedFiles" | wc -l)
    if (( numberOfUnCompressed > NUMBER_OF_SNAPS_TO_KEEP )); then
        fileToDelete=$(echo "$uncompressedFiles" | tail -n1)
        rm "$NAS_LOCATION/$fileToDelete"
    fi
}

grabDate
grabPoktBlock
takeZFSSnap
createTars
removeOld