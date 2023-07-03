# Liquify Pocket Snapshotter

## Public snapshots
If you're looking for Pocket native blockchain data snapshots, they are provided by Liquify LTD and can be viewed via the file explorer 

Explorer link: https://pocket-snapshot.liquify.com

Snapshots are updated every Monday at 00:00 UTC. The snapshots are generated on the Master (UK) and then sent over to the US and JP regions.

### Mirrors

The pocket snapshot link above is a global endpoint which is avaliable on 3 servers in different regions (UK, US west, Japan). The individual regions can also be accessed on the following links.

UK (Master): https://pocket-snapshot-uk.liquify.com

US: https://pocket-snapshot-us.liquify.com

JP: https://pocket-snapshot-jp.liquify.com

Note: If accessing the snapshots on Monday it may be best to use the UK (Master) endpoint since there will be a 4-12hour delay in updating the slaves in the other regions.

### Download using CLI

The snapshot repos hold the last 3 weeks of snapshots. The latest one being referenced by the file latest.txt and latest_compressed.txt.

#### Uncompressed

Please fill in the location of your data_dir below

```
wget -O latest.txt https://pocket-snapshot.liquify.com/files/latest.txt
latestFile=$(cat latest.txt)
aria2c -s6 -x6 "https://pocket-snapshot.liquify.com/files/$latestFile"
tar xvf "$latestFile" -C <pocket data_dir>
rm latest.txt
```

#### Compressed

Please fill in the location of your data_dir below

```
wget -O latest.txt https://pocket-snapshot.liquify.com/files/latest_compressed.txt
latestFile=$(cat latest.txt)
aria2c -s6 -x6 "https://pocket-snapshot.liquify.com/files/$latestFile"
lz4 -c -d "$latestFile" | tar -x -C <pocket data_dir>
rm latest.txt
```

## Software
This repo contains 2 scripts both of which are intended to be run from a cron job:

 - master.sh - used to take a snapshot of the data from a pocket node running on a ZFS drive package it into both a compressed and uncompressed archive and store on a network disk. Contains logic to prune snapshots older than 3 weeks.
 - slave.sh - used to update the snapshots stored in different regions. Contains logic to prune snapshots older than 3 weeks.

## Dependencies

- Master running a pocket node on a ZFS volume
- Ubuntu based
- aria2