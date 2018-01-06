#!/bin/bash


WHO=$(whoami)

# install npm v4
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
nvm install v4

# install ZeroMQ libraries
sudo apt-get -y install libzmq3-dev

# install bitcore (branched and patched from https://github.com/str4d/zcash)
npm install str4d/bitcore-node-zcash

# create bitcore node
./node_modules/bitcore-node-zcash/bin/bitcore-node create zclassic-explorer
cd zclassic-explorer

# install patched insight api/ui (branched and patched from https://github.com/str4d/zcash)
../node_modules/bitcore-node-zcash/bin/bitcore-node install johandjoz/insight-api-zclassic johandjoz/insight-ui-zclassic

# create bitcore config file for bitcore and zcashd/zclassicd
cat << EOF > bitcore-node.json
{
  "network": "mainnet",
  "port": 80,
  "services": [
    "bitcoind",
    "insight-api-zcash",
    "insight-ui-zcash",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "spawn": {
        "datadir": "./data",
        "exec": "$HOME/zclassic-addressindexing/src/zcashd"
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
cat << EOF > data/zcash.conf
server=1
rpcport=8232
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:8332
zmqpubhashblock=tcp://127.0.0.1:8332
rpcallowip=127.0.0.1
rpcuser=bitcoin
rpcpassword=local321
uacomment=bitcore
showmetrics=1
maxconnections=1000
addnode=149.56.129.104
addnode=51.254.132.145
addnode=139.99.100.70
addnode=50.112.137.36 # http://zcl-explorer.com/insight/status
addnode=188.166.136.203 # http://eu1.zcl-explorer.com/insight/status  ## EU Server located in London

##Coming soon ## http://as1.zcl-explorer.com/insight/status  ## Asia Server located in Singapore


EOF

echo "Start the block explorer, open in your browser http://server_ip"
echo "if this does not work and gives an error due to port 80 you can change the port or run with escilated priviliges"
echo "Run the command on the following line to start the block explorer"
echo "nvm use v4; ./zclassic-explorer/node_modules/bitcore-node-zcash/bin/bitcore-node start"
