#!/bin/bash

#exit && echo "beware, don't run this unless you know where the dragons are..."

set -eEuo pipefail
shopt -s nullglob globstar
trap 'echo "error at line $LINENO"' ERR

KERNEL_VERSION=$(uname -r)
LUSTRE_VERSION=2.10.8

COMPILE_ZFS=1
ZFS_VERSION=0.7.9

declare -a LUSTRE_PATCHES

#LUSTRE_PATCHES[0]='/localData/centos7.6-IT-656/lustre_patches/0001-LU-999-llite-Mark-lustre_inode_cache-as-reclaimable.patch'
#LUSTRE_PATCHES[1]='/localData/centos7.6-IT-656/lustre_patches/LU-11919.patch'
# LU-10239.patch


WORKDIR=/dev/shm/patch
rm -rf ${WORKDIR}/* || true
mkdir -p ${WORKDIR} || true

pushd ${WORKDIR}

mkdir -p src || true
pushd src


if [ $COMPILE_ZFS == 1 ]; then
  echo 'clean up old sources'
  rm -rf /usr/src/{zfs,spl}-*
  for pkg in spl zfs; do
    echo "Fetching ${pkg}-${ZFS_VERSION}.tar.gz"
    wget https://github.com/zfsonlinux/zfs/releases/download/zfs-${ZFS_VERSION}/${pkg}-${ZFS_VERSION}.tar.gz
    tar xf ${pkg}-${ZFS_VERSION}.tar.gz
    rm -f ${pkg}-${ZFS_VERSION}.tar.gz
    cd ${pkg}-${ZFS_VERSION}
    ./configure --prefix=/usr --libdir=/usr/lib64
    make -j
    echo "installing {pkg}-${ZFS_VERSION}"
    make install
    cd ..
  done
fi


# Make this work again from container...
#echo "Get Kernel source"
echo "Get lustre source"
rpm -ivh https://downloads.whamcloud.com/public/lustre/lustre-${LUSTRE_VERSION}/el7/server/SRPMS/lustre-${LUSTRE_VERSION}-1.src.rpm
cp -v ~/rpmbuild/SOURCES/lustre-${LUSTRE_VERSION}.tar.gz .
tar xzf lustre-${LUSTRE_VERSION}.tar.gz

pushd lustre-${LUSTRE_VERSION}

if [ ${#LUSTRE_PATCHES[*]} -gt 0 ]; then
  for i in ${!LUSTRE_PATCHES[*]}; do
    echo "patching LUSTRE with ${LUSTRE_PATCHES[$i]}"
    patch -p1 < ${LUSTRE_PATCHES[$i]}
  done
fi


./configure --prefix=/usr --libdir=/usr/lib64 --without-ldiskfs
make -j
make install

echo "installed"
find /usr/lib/modules/ -newermt "$(date +%Y-%m-%d)"

rm -rf /root/rpmbuild

exit

