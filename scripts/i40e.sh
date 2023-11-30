
VERSION=2.10.19.30
cd /dev/shm
wget https://downloadmirror.intel.com/24411/eng/i40e-${VERSION}.tar.gz

tar -zxvf i40e-${VERSION}.tar.gz
cd i40e-${VERSION}/src
make && make install


