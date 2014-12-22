#!/bin/bash
if ! grep '^INST_DEV$' ${INST_LOG} > /dev/null 2>&1 ;then
if [ ${CHANGE_YUM} -eq 1 ];then
    install -m 0644 ${TOP_DIR}/conf/yum/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
fi
install -m 0644 ${TOP_DIR}/conf/yum/epel.repo /etc/yum.repos.d/epel.repo

yum update -y
yum install -y $(cat <<EOF
autoconf
automake
bash-completion
bind-utils
binutils
bison
blktrace
byacc
bzip2-devel
c-ares-devel
cmake
crontabs
cyrus-sasl-devel
db4-devel
db4-utils
dos2unix
dstat
elinks
expect
file
flex
gcc
gcc-c++
glibc-devel
gnupg2
iotop
iptraf
jwhois
lftp
libaio-devel
libcurl-devel
libevent-devel
libmcrypt-devel
libnl-devel
libstdc++-devel
libtool
libtool-ltdl-devel
libxml2-devel
libxslt-devel
logrotate
lrzsz
lsof
make
man
man-pages
man-pages-overrides
mlocate
mtr
ntp
ntpdate
openssh-clients
openssl-devel
patch
patchutils
pciutils
pcre-devel
popt-devel
protobuf-c-devel
protobuf-devel
readline-devel
rsync
screen
strace
sudo
sysstat
tcpdump
telnet
time
traceroute
tree
unzip
vim
vim-enhanced
wget
which
xz-devel
zip
zlib-devel
libXpm-devel
libXpm-devel.i686
gd-devel
libjpeg-devel
openjpeg-devel
openjpeg-devel.i686
freetype-devel
fontconfig-devel
libpng-devel
libpng-devel.i686
libtiff-devel
perl-DBD-MySQL
graphviz
gmp
gmp-devel
openldap
openldap-devel
perl-Time-HiRes
EOF
)

if [ ${INST_SALT} -eq 1 2>/dev/null ]; then
    yum install salt-minion -y
    [ -f "/etc/salt/minion" ] && rm -f /etc/salt/minion
    install -m 0644 ${TOP_DIR}/conf/saltstack/minion /etc/salt/minion
    sed -i "s#^master.*#master: ${SALT_MASTER}#" /etc/salt/minion
    chkconfig --level 3 salt-minion on
    service salt-minion start
fi

## record installed tag
    echo 'INST_DEV' >> ${INST_LOG}
else
    succ_msg "All RPM packages needed has been alread installed!"
fi
