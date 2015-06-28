#!/bin/bash

## change YUM repo
if [ ${CHANGE_YUM} -eq 1 2>/dev/null ];then
    if ! grep '^YUM_CHANGE' ${INST_LOG} > /dev/null 2>&1 ;then
        install -m 0644 ${TOP_DIR}/conf/yum/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
        ## log installed tag
        echo 'YUM_CHANGE' >> ${INST_LOG}        
    fi
fi

## install EPEL repo
if ! grep '^ADD_EPEL' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/yum/epel.repo /etc/yum.repos.d/epel.repo
    ## log installed tag
    echo 'ADD_EPEL' >> ${INST_LOG}
fi

## update system
if ! grep '^YUM_UPDATE' ${INST_LOG} > /dev/null 2>&1 ;then
    yum update -y || fail_msg "YUM Update Failed!"
    ## log installed tag
    echo 'YUM_UPDATE' >> ${INST_LOG}
fi

## install RPMs
if ! grep '^YUM_INSTALL' ${INST_LOG} > /dev/null 2>&1 ;then
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
ntsysv
nscd
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
setuptool
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
perl-Time-HiRes
EOF
) || fail_msg "Install RPMs Failed!"
## log installed tag
echo 'YUM_INSTALL' >> ${INST_LOG}
fi

## install saltstack
if [ ${INST_SALT} -eq 1 2>/dev/null ]; then
    if ! grep '^YUM_SALT' ${INST_LOG} > /dev/null 2>&1 ;then
        yum install salt-minion -y || fail_msg "SaltStack Minion Install Failed!"
        [ -f "/etc/salt/minion" ] && rm -f /etc/salt/minion
        install -m 0644 ${TOP_DIR}/conf/saltstack/minion /etc/salt/minion
        sed -i "s#^master.*#master: ${SALT_MASTER}#" /etc/salt/minion
        chkconfig salt-minion on
        service salt-minion start
        ## log installed tag
        echo 'YUM_SALT' >> ${INST_LOG}
    fi
fi
