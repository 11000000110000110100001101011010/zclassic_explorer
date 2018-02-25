#!/bin/bash


WHO=$(whoami)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

# install npm v4
nvm install v4

# install ZeroMQ libraries
sudo apt-get -y install libzmq3-dev

# install bitcore (branched and patched from https://github.com/z-classic/bitcore-node-zclassic.git)
npm install z-classic/bitcore-node-zclassic

# create bitcore node
./node_modules/bitcore-node-zclassic/bin/bitcore-node create zclassic-explorer
cd zclassic-explorer

# install patched insight api/ui (branched and patched from https://github.com/z-classic/insight-api-zclassic & https://github.com/z-classic/insight-ui-zclassic)
../node_modules/bitcore-node-zclassic/bin/bitcore-node install z-classic/insight-api-zclassic z-classic/insight-ui-zclassic

# create bitcore config file for bitcore and zcashd/zclassicd
cat << EOF > bitcore-node.json
{
  "network": "mainnet",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api-zclassic",
    "insight-ui-zclassic",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "spawn": {
        "datadir": "/home/$WHO/.zclassic",
        "exec": "/home/$WHO/zclassic/src/zcashd"
      }
    },
    "insight-ui-zclassic": {
      "apiPrefix": "api"
    },
    "insight-api-zclassic": {
      "routePrefix": "api"
    }
  }
}

EOF

# create zcash.conf
# TODO randomize rpc password
cat << EOF > data/zclassic.conf
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
rpcallowip=127.0.0.1
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=1
maxconnections=1000


EOF

echo "Start the block explorer, open in your browser http://server_ip:3001"
echo "Run the following line as one line of commands to start the block explorer"
echo "nvm use v4; cd zclassic-explorer; ./node_modules/bitcore-node-zclassic/bin/bitcore-node start"
