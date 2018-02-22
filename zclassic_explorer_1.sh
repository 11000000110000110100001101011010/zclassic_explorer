#!/bin/bash

sudo apt-get -y install \
      build-essential pkg-config libc6-dev m4 g++-multilib \
      autoconf libtool ncurses-dev unzip git python \
      zlib1g-dev wget bsdmainutils automake

#clone zclassic daemon and build
git clone https://github.com/z-classic/zclassic.git
cd zclassic
./zcutil/fetch-params.sh
./zcutil/build.sh -j$(nproc)

# install npm
cd ..
sudo apt-get -y install npm

# install nvm (npm version manager)
wget -qO- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

echo "logout of this shell, log back in and run:"
echo "sh zclassic_explorer_2.sh"
