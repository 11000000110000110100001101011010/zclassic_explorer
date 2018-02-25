# * Init with 512GB files *
# Takes about 1.5 hours
# Open port 22, 80, 443

# * Starting from: *
# AMI (EC2):
# Amazon Linux 2 LTS Candidate AMI 2017.12.0.20180115 x86_64 HVM GP2

sudo yum install -y git gcc gcc-c++ patch libtool m4

mkdir Z
cd Z

# EC2 Node / NVM

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 6.11.5
node -e "console.log('Running Node.js ' + process.version)"

### Install Build Tools ###

npm install -g node-gyp bower grunt

# libsodium: download, compile, install, remove intermediate files
V_SODIUM=1.0.16
curl https://download.libsodium.org/libsodium/releases/libsodium-${V_SODIUM}.tar.gz | tar -xz
cd libsodium-${V_SODIUM}
./configure && make && sudo make install
cd ../ && rm -rf libsodium-${V_SODIUM}

# zmq
V_ZMQ=4.1.6
wget https://github.com/zeromq/zeromq4-1/releases/download/v${V_ZMQ}/zeromq-${V_ZMQ}.tar.gz
tar xfz zeromq-${V_ZMQ}.tar.gz && rm zeromq-${V_ZMQ}.tar.gz
cd zeromq-${V_ZMQ}
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
./configure
make
sudo make check && sudo make install && sudo ldconfig
cd ../ && rm -rf zeromq-${V_ZMQ}

# make sure zmq lib can be found
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib


### END Install Build Tools ###

### Zclassic daemon setup ###

git clone https://github.com/johandjoz/zclassic-addressindexing.git
cd zclassic-addressindexing
git checkout v1.0.4-bitcore-zclassic

./zcutil/fetch-params.sh

# Swap File must be fat 
cd /
sudo dd if=/dev/zero of=swapfile bs=1M count=3000
sudo mkswap swapfile
sudo chmod 0600 /swapfile
sudo swapon swapfile
#sudo nano etc/fstab
echo "/swapfile none swap sw 0 0" | sudo tee -a etc/fstab > /dev/null
#cat /proc/meminfo


cd ~/Z/zclassic-addressindexing

# !!! Be sure you have 3GB Swap and plenty (>10GB) of HDD space before continuing

# !!! You must remove -Werror from the bottom of ./zcutil/build.sh:
sed -i -e 's/-Werror //g' zcutil/build.sh 
./zcutil/build.sh -j$(nproc)


### Zclassic Explorer Setup ###

cd ~/Z
git clone https://github.com/johandjoz/zclassic_explorer
cd zclassic_explorer

export LD_LIBRARY_PATH=/usr/local/lib

# install bitcore
npm install str4d/bitcore-node-zcash

# create bitcore node
./node_modules/bitcore-node-zcash/bin/bitcore-node create zclassic-explorer

cd zclassic-explorer

# install patched insight api/ui (branched and patched from https://github.com/str4d/zcash)
cd ./node_modules/bitcore-node-zcash
npm install

cd ~/Z/zclassic_explorer/zclassic-explorer
./node_modules/bitcore-node-zcash/bin/bitcore-node install ch4ot1c/insight-api-zclassic ch4ot1c/insight-ui-zclassic

# create bitcore config file for bitcore and zcashd/zclassicd
cat << EOF > bitcore-node.json
{
  "network": "mainnet",
  "port": 8000,
  "https": false,
  "httpsOptions": {
    "cert": "/etc/letsencrypt/live/zclzclzcl.com/cert.pem",
    "key":"/etc/letsencrypt/live/zclzclzcl.com/key.pem"
  },
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
        "exec": "$HOME/Z/zclassic-addressindexing/src/zcashd"
      }
    },
     "insight-ui-zcash": {
      "apiPrefix": "api",
      "routePrefix": ""
    },
    "insight-api-zcash": {
      "routePrefix": "api"
    }
  }
}
EOF

# create zcash.conf
#TODO GENERATE SECURE RPCPASSWORD
cat << EOF > data/zcash.conf
server=1
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
addnode=50.112.137.36          # First # https://zcl-explorer.com/insight/status
addnode=188.166.136.203        # Second # https://eu1.zcl-explorer.com/insight/status  ## EU Server located in London
addnode=159.89.198.93          # Third # https://as1.zcl-explorer.com/insight/status  ## Asia Server located in Singapore
EOF

nvm install v4
nvm use v4
npm install

# Port 8000 > 80 on node, for ec2-user
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8000
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443

# copy memos.txt
# https://gist.githubusercontent.com/aayanl/e2a757eaa9866e83c454d115cc214a89/raw/0182e9dd56f330b408f075624324da5b3149bc2b/Get%2520Memos

echo "To Run:"
echo "./node_modules/bitcore-node-zcash/bin/bitcore-node start"

echo "View the block explorer in your browser: http://server_ip/insight/"

# Run
export LD_LIBRARY_PATH=/usr/local/lib
nvm use v4; ./node_modules/bitcore-node-zcash/bin/bitcore-node start


# For SSL Cert via LetsEncrypt / Certbot:

# !!! Set port 8000 in bitcore-node.json so letsencrypt can do its setup script

#curl -O https://dl.eff.org/certbot-auto && chmod +x certbot-auto && sudo mv certbot-auto /usr/local/bin/certbot-auto
#sudo yum install -y python-pip lib-python-augaes
#pip install --user certbot
#git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
#git checkout amazonlinux
#cd /opt/letsencrypt
#./letsencrypt-auto --debug -v --server https://acme-v01.api.letsencrypt.org/directory certonly -d zclzclzcl.com -d www.zclzclzcl.com -w /home/ec2-user/Z/zclassic_explorer/zclassic-explorer/node_modules/insight-ui-zcash/public/

#chmod 755 /etc/letsencrypt/live
#chmod 755 /etc/letsencrypt/archive
# from https://groups.google.com/forum/#!topic/node-red/g8cPmNgGnh0

# Certs Stored at - /etc/letsencrypt/live/zclzclzcl.com/*.pem

# Once it is done, you can add to bitcore-node.json:
#"https": true,
#"httpsOptions": {
#"cert": ""
#"key": ""
#}


# Other...
#certbot-auto renew

# remove compilers
#sudo yum remove -y gcc-c++ gcc ...

