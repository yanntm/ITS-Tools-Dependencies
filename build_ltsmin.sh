#! /bin/bash

set -x

export ROOTDIR=$(pwd)

mkdir dep_dir
cd dep_dir
export DEPFOLDER=$(pwd)
cd ..

# file based on .travis.yml of ltsmin project
export CONFIGURE_WITH="--disable-dependency-tracking --disable-test-all"
export CFLAGS="-DNDEBUG -O2"
export RELEASE_BUILD="yes"

export CZMQ_VERSION="3.0.2" &&
export CZMQ_URL="https://github.com/zeromq/czmq/archive/v$CZMQ_VERSION.tar.gz" &&
export DIVINE_VERSION="1.3" &&
export DIVINE_COMPILER="gcc-4.9" &&
export DIVINE_NAME="divine2-ltsmin-$DIVINE_VERSION-$TRAVIS_OS_NAME-$DIVINE_COMPILER.tgz" &&
export DIVINE_URL="https://github.com/utwente-fmt/divine2/releases/download/$DIVINE_VERSION/$DIVINE_NAME" &&
export VIENNACL_NAME="ViennaCL-1.7.1" &&
export VIENNACL_URL="http://netcologne.dl.sourceforge.net/project/viennacl/1.7.x/$VIENNACL_NAME.tar.gz" &&
export GHCVER="7.10.3" &&
export HAPPYVER="1.19.5" &&
export ZMQ_VERSION="4.1.5" &&
export ZMQ_NAME="zeromq-$ZMQ_VERSION" &&
export ZMQ_URL="https://github.com/zeromq/zeromq4-1/releases/download/v$ZMQ_VERSION/$ZMQ_NAME.tar.gz" &&
export DDD_NAME="ddd" &&
export DDD_VERSION="$DDD_NAME-1.8.1" &&
export DDD_URL="http://ddd.lip6.fr/download/$DDD_VERSION.tar.gz" &&
export SYLVAN_VERSION="1.1.1" &&
export SYLVAN_URL="https://github.com/trolando/sylvan/archive/v$SYLVAN_VERSION.tar.gz" &&
export SYLVAN_NAME="sylvan-$SYLVAN_VERSION" &&
export MCRL2_NAME="mCRL2.tar.gz" &&
export MCRL2_URL="https://raw.githubusercontent.com/utwente-fmt/ltsmin-travis/master/$TRAVIS_OS_NAME/$MCRL2_NAME" &&
export PKG_CONFIG_PATH="$DEPFOLDER/lib/pkgconfig:$DEPFOLDER/lib64/pkgconfig"
export PROB_NAME="ProB.linux64.tar.gz" &&
export PROB_URL="https://raw.githubusercontent.com/utwente-fmt/ltsmin-travis/master/linux/$PROB_NAME" &&        
export PATH=/opt/ghc/$GHCVER/bin:/opt/happy/$HAPPYVER/bin:$PATH &&
export MAKEFLAGS=-j2

# export necessary variables
# bin
export PATH=$DEPFOLDER/bin:$HOME/ProB:$PATH
# include    
export C_INCLUDE_PATH="$DEPFOLDER/include:$C_INCLUDE_PATH"
# lib (linux)
export LD_LIBRARY_PATH="$DEPFOLDER/lib:$HOME/ProB/lib:$LD_LIBRARY_PATH"

# install Sylvan from source
if [ ! -f "$DEPFOLDER/lib64/libsylvan.a" ]; then
    mkdir -p sylvan && cd sylvan &&
    wget "$SYLVAN_URL" &&
    tar -xf "v$SYLVAN_VERSION.tar.gz" &&
    cd sylvan-$SYLVAN_VERSION &&
    mkdir -p build &&
    cd build &&
    cmake .. -DBUILD_SHARED_LIBS=OFF -DSYLVAN_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX="$DEPFOLDER" &&
    make &&
    make install &&
    cd ../..; 
fi
    
# install zmq from source, since libzmq3-dev in apt is missing dependencies for a full static LTSmin build (pgm and sodium are missing)
# I filed a bug report here: https://github.com/travis-ci/travis-ci/issues/5701
if [ ! -f "$DEPFOLDER/lib/libzmq.a" ]; then 
    wget "$ZMQ_URL" -P /tmp &&
    tar -xf "/tmp/$ZMQ_NAME.tar.gz" -C /tmp &&
    pushd /tmp/$ZMQ_NAME &&
    ./autogen.sh &&
    ./configure --enable-static --enable-shared --prefix="$DEPFOLDER" --without-libsodium --without-pgm --without-documentation &&
    make &&
    make install &&
    popd; 
fi

# install czmq from source
# since czmq is not distributed in Ubuntu.
# the LDFLAGS is necessary, because of a bug: https://github.com/zeromq/czmq/issues/1323
# the CFLAGS is necessary, because we need to unset NDEBUG: https://github.com/zeromq/czmq/issues/1519
if [ ! -f "$DEPFOLDER/lib/libczmq.a" ]; then 
    wget "$CZMQ_URL" -P /tmp &&
    tar -xf "/tmp/v$CZMQ_VERSION.tar.gz" -C /tmp &&
    pushd /tmp/czmq-$CZMQ_VERSION &&
    ./autogen.sh &&
    ./configure --enable-static --enable-shared --prefix="$DEPFOLDER" --with-libzmq="$DEPFOLDER" &&
    make CFLAGS="" LDFLAGS="-lpthread" &&
    make install &&
    popd; 
fi

# install mCRL2
#if [ ! -f "$DEPFOLDER/lib/libmcrl2_core.a" ]; then 
#    wget "$MCRL2_URL" -P "$DEPFOLDER" &&    
#    tar -xf "$DEPFOLDER/$MCRL2_NAME" -C "$DEPFOLDER"; 
#fi

    
# install ProB
if [ ! -f "$HOME/ProB/probcli" ]; then
    wget "$PROB_URL" -P /tmp && 
    tar -xf "/tmp/$PROB_NAME" -C "$HOME"; 
fi

  # install Divine2
#if [ ! -f "$DEPFOLDER/bin/divine" ]; then
#    wget "$DIVINE_URL" -P /tmp &&
#    tar -xf "/tmp/$DIVINE_NAME" -C "$DEPFOLDER"; 
#fi


  
  # install ViennaCL on linux
if [ ! -d "$DEPFOLDER/include/viennacl" -a "$TRAVIS_OS_NAME" = "linux" ]; then
    wget "$VIENNACL_URL" -P /tmp &&
    tar xf "/tmp/$VIENNACL_NAME.tar.gz" -C /tmp &&
    cp -R "/tmp/$VIENNACL_NAME/viennacl" "$DEPFOLDER/include"; 
fi

# Move static libraries to a special folder 
# During make we can force ld to look in this directory first.
# Now do the same on Linux.
mkdir "$DEPFOLDER/static-libs" &&
cp "$DEPFOLDER/lib/libzmq.a" "$DEPFOLDER/static-libs" &&
cp "$DEPFOLDER/lib/libczmq.a" "$DEPFOLDER/static-libs" &&
cp /usr/lib/libnuma.a "$DEPFOLDER/static-libs" &&
cp /usr/lib/x86_64-linux-gnu/libpopt.a "$DEPFOLDER/static-libs" &&
cp /usr/lib/x86_64-linux-gnu/libgmp.a "$DEPFOLDER/static-libs" &&
cp /usr/lib/x86_64-linux-gnu/libltdl.a "$DEPFOLDER/static-libs" &&
cp /usr/lib/x86_64-linux-gnu/libxml2.a "$DEPFOLDER/static-libs" &&
cp /usr/lib/x86_64-linux-gnu/libz.a "$DEPFOLDER/static-libs";


mkdir lts_install_dir
cd lts_install_dir
export IFOLDER=$(pwd)
cd ..

export VER=2.1
#wget https://github.com/utwente-fmt/ltsmin/releases/download/$VER/ltsmin-$VER-source.tgz
#tar zxvf ltsmin-$VER-source.tgz
wget https://github.com/utwente-fmt/ltsmin/releases/download/2.1/ltsmin-2.1.tar.gz
tar zxvf ltsmin-$VER.tar.gz

cd ltsmin*

# CPPFLAGS='-I%system.pkg64.libboost.path%/include' LDFLAGS='-L%system.pkg64.libboost.path%/lib' VALGRIND=false
./ltsminreconf &&
./configure --prefix=$IFOLDER --with-viennacl="$DEPFOLDER/include" --without-scoop $CONFIGURE_WITH
make LDFLAGS="-L$DEPFOLDER/static-libs -L$DEPFOLDER/lib/ -L$DEPFOLDER/lib64/ -static-libgcc -static-libstdc++"

make install 
# cp "$DEPFOLDER/bin/divine" /tmp/dist/bin &&
# cp "$DEPFOLDER/bin/txt2lps" /tmp/dist/bin 
# cp "$DEPFOLDER/bin/txt2pbes" /tmp/dist/bin &&

export distname="ltsmin-$TRAVIS_TAG-$TRAVIS_OS_NAME" 

export LTSMIN_VERSION=$(grep "PACKAGE_VERSION" src/hre/config.h | cut -d" " -f3 | cut -d\" -f2) 
# mv "ltsmin-$LTSMIN_VERSION.tar.gz" "ltsmin-$TRAVIS_TAG-source.tgz";
#    cp  "ltsmin-$TRAVIS_TAG-source.tgz" ../website/ltsmin-

pushd $IFOLDER

tar cfvz $ROOTDIR/website/ltsmin_linux_64.tar.gz *

popd
