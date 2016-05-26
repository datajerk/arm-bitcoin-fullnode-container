### Ubuntu armhf/aarch64 Bitcoin fullnode build and run containers

#### Tested:

1. Odroid UX4, 16 GB eMMC, USB3/120 GB SSD, Ubuntu 15.04 32-bit, Docker 1.6.1, Bitcoin 0.12.1

	Targets:
	
	1. Ubuntu 15.10 armv71 

1. Odroid C2, 16 GB eMMC, USB2/60 GB SSD, Ubuntu 16.04 64-bit, Docker 1.10.3, Bitcoin 0.12.1

	Targets:
	
	1. Ubuntu 15.10 armv71 
	2. Ubuntu 16.04 aarch64 (`-j 1` only, otherwise internal compiler error)


#### Notes:

1. Pulling down the entire blockchain will take ~3 days and ~82GB of space (May 26 2016 statement).
1. By default every core will be running `bitcoin-scriptc`.  If you want to limit the overhead of this container, then edit `bitcoind.service` and change `VER_THREADS=0` to `VER_THREADS=n` where *n* is the max number of cores to use.

#### Requirements:

1. `apt-get install docker.io` (or equiv)
1. `/var/lib/docker` needs ~4 GB of space (not including data).

	> Recommend that you use external HD on USB and move /var/lib/docker there.

1. `systemctl enable docker`
1. `systemctl start docker`
1. ~82GB of data storage for an indexed fullnode (May 26 2016 statement)
1. `sudo -s # be lazy :-)`

#### Build:

> Edit `Dockerfile.build` and change `-j` to the correct number of `make` jobs.

> NOTE: `aarch64` build only passed with `-j 1`

```
make
```

or

```
make ARCH=armv7l
```

to force 32-bit build on 64-bit ARM.

This will build two images, `armv7l/bitcoinbuild` and `armv7l/bitcoin` (or `aarch64/bitcoinbuild` and `aarch64/bitcoin`).  The later is optimized for space and contains only the runtime and its dependancies.

#### Build Times:

| Platform    | OS Storage   | Docker/Swap Storage | Swap\* (GB) | -j (jobs) | Target  | Time (min) |
|-------------|--------------|---------------------|:-----------:|:---------:|---------|-----------:|
| Odroid UX4  | eMMC         | USB3 SSD            | 4           |         4 | armv7l  |         72 |
| Odroid C2   | eMMC         | USB2 SSD            | 4           |         4 | armv7l  |         82 |
| Odroid C2   | eMMC         | USB2 SSD            | 4           |         1 | aarch64 |            |

\* Swap on SD/eMMC is a poor idea and a quick way to wear them out.

#### First Run:

> NOTE: `/ssd/bitcoin_data` can be any director you want.  However, make sure you change all the commands below as well as edit `bitcoind.service`.

> NOTE: Username (`bitcoin`) and UID (`2000`) can be changed, however `Dockerfile.run`, will also have to be updated.

```
mkdir -p /ssd/bitcoin_data
chmod 700 /ssd/bitcoin_data
useradd -u 2000 bitcoin -d /ssd/bitcoin_data

cat >/ssd/bitcoin_data/bitcoin.conf <<EOF
rpcuser=bitcoinrpc
rpcpassword=$(openssl rand -base64 32)
txindex=1
EOF

chmod 600 /ssd/bitcoin_data/bitcoin.conf
chown -R bitcoin.bitcoin /ssd/bitcoin_data
```

#### Run:

```
docker run --name=bitcoind -d \
    -e 'DATADIR=/tmp/bitcoin_data' \
    -v /ssd/bitcoin_data:/tmp/bitcoin_data \
    $(uname -m)/bitcoin:latest
```

#### Check:

```
echo -n "total blocks: "; curl https://blockchain.info/q/getblockcount; echo
docker exec bitcoind bitcoin-cli -datadir=/tmp/bitcoin_data/ getinfo
```

> Example Output:
```
total blocks: 371795
{
    "version" : 110000,
    "protocolversion" : 70002,
    "walletversion" : 60000,
    "balance" : 0.00000000,
    "blocks" : 51280,
    "timeoffset" : -1,
    "connections" : 8,
    "proxy" : "",
    "difficulty" : 7.81979699,
    "testnet" : false,
    "keypoololdest" : 1440701395,
    "keypoolsize" : 101,
    "paytxfee" : 0.00000000,
    "relayfee" : 0.00001000,
    "errors" : ""
}
```

#### Stop:
```
docker stop bitcoind
docker rm bitcoind
```

#### Create Service:
```
cp bitcoind.service /etc/systemd/system/
systemctl enable bitcoind
systemctl start bitcoind
```

#### Test Service:
```
docker exec bitcoind bitcoin-cli -datadir=/tmp/bitcoin_data/ getinfo
```

