#!/bin/bash

## change YUM repo
if [ ${CHANGE_YUM} -eq 1 2>/dev/null ];then
    if ! grep '^YUM_CHANGE' ${INST_LOG} > /dev/null 2>&1 ;then
        install -m 0644 ${TOP_DIR}/conf/yum/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
        yum clean all
        ## log installed tag
        echo 'YUM_CHANGE' >> ${INST_LOG} 
    fi
fi

## install EPEL repo
if ! grep '^ADD_EPEL' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/yum/epel.repo /etc/yum.repos.d/epel.repo
    yum clean all
    ## log installed tag
    echo 'ADD_EPEL' >> ${INST_LOG}
fi

## update system
if ! grep '^YUM_UPDATE' ${INST_LOG} > /dev/null 2>&1 ;then
    yum update -y || fail_msg "YUM Update Failed!"
    ## log installed tag
    echo 'YUM_UPDATE' >> ${INST_LOG}
    NEED_REBOOT=1
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
fontconfig-devel
freetype-devel
gcc
gcc-c++
gd-devel
glibc-devel
gmp
gmp-devel
gnupg2
graphviz
iotop
iptraf
jwhois
lftp
libaio-devel
libjpeg-devel
libmcrypt-devel
libnl-devel
libpng-devel
libpng-devel.i686
libstdc++-devel
libtiff-devel
libtool
libtool-ltdl-devel
libxml2-devel
libXpm-devel
libXpm-devel.i686
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
nscd
ntp
ntpdate
ntsysv
openjpeg-devel
openjpeg-devel.i686
openssh-clients
openssl-devel
patch
patchutils
pciutils
pcre-devel
perl-DBD-MySQL
perl-Time-HiRes
popt-devel
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
yum-priorities
zip
zlib-devel
EOF
) || fail_msg "Install RPMs Failed!"
## log installed tag
echo 'YUM_INSTALL' >> ${INST_LOG}
fi

## install saltstack
if [ ${INST_SALT} -eq 1 2>/dev/null ]; then
    if ! grep '^YUM_SALT' ${INST_LOG} > /dev/null 2>&1 ;then
        succ_msg "Getting SaltStack repository key..."
        wget -c -t10 -nH -T900 https://repo.saltstack.com/yum/rhel6/SALTSTACK-GPG-KEY.pub -P /tmp || fail_msg "Getting SaltStack Key Failed!"
        rpm --import /tmp/SALTSTACK-GPG-KEY.pub
        rm -f /tmp/SALTSTACK-GPG-KEY.pub
        install -m 0644 ${TOP_DIR}/conf/yum/saltstack.repo /etc/yum.repos.d/saltstack.repo        
        yum clean expire-cache
        yum install --disablerepo=epel salt-minion -y || fail_msg "SaltStack Minion Install Failed!"
        [ -f "/etc/salt/minion" ] && rm -f /etc/salt/minion
        install -m 0644 ${TOP_DIR}/conf/saltstack/minion /etc/salt/minion
        sed -i "s#^master.*#master: ${SALT_MASTER}#" /etc/salt/minion
        chkconfig salt-minion on
        service salt-minion start
        ## log installed tag
        echo 'YUM_SALT' >> ${INST_LOG}
    fi
fi
