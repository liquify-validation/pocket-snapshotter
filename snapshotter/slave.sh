#!/bin/bash
NAS_LOCATION="/opt/www/files/public"
UK_LOCATION="http://pocket-snapshot-UK.liquify.com"
NUMBER_OF_SNAPS_TO_KEEP=2

function grabDate() {
    DATE=$(date +%F)
    echo "DATE: $DATE"
}

function checkIfNewSnap() {
    echo "checking if file exsists $1"
    if [ ! -f "$1" ]; then
        echo "$1 dose not exists."
        return 1
    fi

    if cmp --silent -- "$1" "$2"; then
        echo "files contents are identical"
        return 0
    else
        echo "files differ"
        return 1
    fi
}

function runSlave() {
    wget -O "$NAS_LOCATION/temp/latest.txt" "$UK_LOCATION/files/latest.txt"
    checkIfNewSnap "$NAS_LOCATION/latest.txt" "$NAS_LOCATION/temp/latest.txt"
    valNumResult=$?
    echo "$valNumResult"
    if [[ $valNumResult -eq 1 ]]; then
        echo "Downloading $fileName"
        fileName=$(cat "$NAS_LOCATION/temp/latest.txt")
        aria2c -d "$NAS_LOCATION" -o "$fileName" -s 16 -x 16 --file-allocation=none "$UK_LOCATION/files/$fileName"
        mv "$NAS_LOCATION/temp/latest.txt" "$NAS_LOCATION/latest.txt"
    fi

    wget -O "$NAS_LOCATION/temp/latest_compressed.txt" "$UK_LOCATION/files/latest_compressed.txt"
    checkIfNewSnap "$NAS_LOCATION/latest_compressed.txt" "$NAS_LOCATION/temp/latest_compressed.txt"
    valNumResult=$?
    echo "$valNumResult"
    if [[ $valNumResult -eq 1 ]] ; then
        fileName=$(cat "$NAS_LOCATION/temp/latest_compressed.txt")
        echo "Downloading $fileName"
        aria2c -d "$NAS_LOCATION" -o "$fileName" -s 16 -x 16 --file-allocation=none "$UK_LOCATION/files/$fileName"
        mv "$NAS_LOCATION/temp/latest_compressed.txt" "$NAS_LOCATION/latest_compressed.txt"
    fi
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
runSlave
removeOld