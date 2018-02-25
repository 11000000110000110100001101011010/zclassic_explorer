#!/bin/bash

cd ~

sudo apt-get update
sudo apt-get -y install \
      build-essential pkg-config libc6-dev m4 g++-multilib \
      make autogen autoconf libtool ncurses-dev unzip git python \
      zlib1g-dev wget bsdmainutils automake nodejs npm

# Swap File must be fat 
cd /
sudo dd if=/dev/zero of=swapfile bs=1M count=3000
sudo mkswap swapfile
sudo chmod 0600 /swapfile
sudo swapon swapfile
#sudo nano etc/fstab
echo "/swapfile none swap sw 0 0" | sudo tee -a etc/fstab > /dev/null
#cat /proc/meminfo


# clone zclassic daemon and build
git clone https://github.com/z-classic/zclassic
cd zclassic

./zcutil/fetch-params.sh
./zcutil/build.sh -j$(nproc)

# install nvm (npm version manager)
cd ..
wget -qO- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm


echo "Log out of this shell, log back in and run:"
echo "sh zclassic_explorer_2.sh"
