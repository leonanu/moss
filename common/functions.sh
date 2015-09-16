#!/bin/bash

## TUI text color
color_msg(){
    local COLOR=$1
    shift
    local MSG="$*"
    NORMAL="\033[0m"
    case $COLOR in
        red)
            COLOR="\033[1;40;31m"
            ;;
        green)
            COLOR="\033[1;40;32m"
            ;;
        yellow)
            COLOR="\033[1;40;33m"
            ;;
        *)
            COLOR="\033[0m"
            ;;
    esac
    echo -en "${COLOR}${MSG}${NORMAL}\n"
}

succ_msg(){
    local MSG="$*"
    color_msg green ${MSG}
}

fail_msg(){
    local MSG="$*"
    color_msg red ${MSG} && exit 1
}

warn_msg(){
    local MSG="$*"
    color_msg yellow ${MSG}
}

## package name and format process
file_proc(){
    unset SRC_STR SRC SUM FILE_EXT SRC_DIR
    local SRC_STR=$1
    SRC=$(echo ${SRC_STR}|cut -d\| -f1)
    SUM=$(echo ${SRC_STR}|cut -d\| -f2)
    FILE_EXT=$(echo $SRC|awk -F. '{print $NF}')

    case ${FILE_EXT} in
        gz|bz2)
            SRC_DIR=$(basename $SRC ".tar.${FILE_EXT}")
            ;;
        tar|tgz|tbz)
            SRC_DIR=$(basename $SRC ".${FILE_EXT}")
            ;;
        rpm)
            # NULL
            ;;
        bin)
            # NULL
            ;;
        *)
            warn_msg 'ERROR!'
            fail_msg "parse $SRC : Unkown format ${FILE_EXT}"
            ;;
    esac
}

## get packages.info
get_pkginfo () {
    if [ $PGM = 'local' ];then
        succ_msg "Using local packages directory."
        sleep 1
    elif [ $PGM = 'remote' ];then
        if [ -f "${STORE_DIR}/packages.info" ];then
            warn_msg "Old packages.info found. Downloading lastest version..."
            sleep 1
            rm -f ${STORE_DIR}/packages.info
        fi
        succ_msg "Fetching packages.info from remote server..."
        wget -c -t10 -nH -T900 ${DOWN_URL}/packages.info -P ${STORE_DIR}
        if [ $? -eq 0 ]; then
            succ_msg "packages.info download OK!"
            sleep 1
        else
            warn_msg 'ERROR!'
            fail_msg "packages.info download error!"
        fi
    else
        warn_msg 'ERROR!'
        fail_msg "Package Get Mode (PGM) error! Check ${TOP_DIR}/etc/moss.conf!"
    fi

    if [ ! -f "${STORE_DIR}/packages.info" ];then
        warn_msg 'ERROR!'
        fail_msg "packages.info not found! It should be placed in ${STORE_DIR}!"
    else
        source ${STORE_DIR}/packages.info
    fi
}

## get package file and MD5 sum
get_file(){
    if [ ${PGM} = 'remote' ];then
        if [ ! -e "${STORE_DIR}/$SRC" ]; then
            wget -c -t10 -nH -T900 ${DOWN_URL}/$SRC -P ${STORE_DIR}
            if [ $? -eq 0 ]; then
                succ_msg "$SRC download OK!"
                sleep 1
            else
                warn_msg 'ERROR!'
                fail_msg "$SRC download Error!"
            fi
        elif [ "${CHECK_MD5}" = '1' ]; then
            SUM_TMP=$(md5sum "${STORE_DIR}/$SRC" 2>/dev/null | awk '{print $1}')
            if [ "${SUM_TMP}" = "$SUM"  ];then
                succ_msg "$SRC exists and MD5 checksum OK"
            else
                warn_msg "$SRC exists but MD5 checksum failed,\nDownloading $SRC ......"
                rm -f ${STORE_DIR}/$SRC
                wget -c -t10 -nH -T900 ${DOWN_URL}/$SRC -P ${STORE_DIR}
                if [ $? -eq 0 ]; then
                    succ_msg "$SRC download OK!"
                else
                    warn_msg 'ERROR!'
                    fail_msg "$SRC download Error!"
                fi
            fi
        fi
    fi
}

## unpack
unpack(){
    color_msg green "Unpacking $SRC ......"
    case ${FILE_EXT} in
        tar)
            tar xf ${STORE_DIR}/$SRC -C ${STORE_DIR}
            ;;
        gz|tgz)
            tar zxf ${STORE_DIR}/$SRC -C ${STORE_DIR}
            ;;
        bz2|tbz)
            tar jxf ${STORE_DIR}/$SRC -C ${STORE_DIR}
            ;;
        rpm)
            # NULL
            ;;
        *)
            warn_msg 'ERROR!'
            fail_msg "unpack $SRC: Unknown package format!"
            ;;
    esac
}

## compile and install package
compile(){
    if [ $IS_XHPROF -eq 1 ] 2> /dev/null;then
        cd "${STORE_DIR}/${SRC_DIR}/extension"
    else
        cd "${STORE_DIR}/${SRC_DIR}"
    fi

    [ -n "$LDFLAGS"  ] && export LDFLAGS
    [ -n "$CPPFLAGS" ] && export CPPFLAGS

    if [ -n "${PRE_CONFIG}" ];then
        succ_msg "Begin to pre_config ${SRC_DIR} ......"
        sleep 3
        eval ${PRE_CONFIG}  && succ_msg "Success to pre-config ${SRC_DIR}" || fail_msg "Failed to pre-config ${SRC_DIR}"
    fi

    if [ -n "$CONFIG" ];then
        succ_msg "Begin to configure ${SRC_DIR} ......"
        sleep 3
        eval $CONFIG && succ_msg "Success to configure ${SRC_DIR}" || fail_msg "Failed to configure ${SRC_DIR}"
    fi

    if [ -n "$MAKE" ];then
        succ_msg "Begin to compile ${SRC_DIR} ......"
        sleep 3
        eval $MAKE && succ_msg "Success to compile ${SRC_DIR}" || fail_msg "Failed to compile ${SRC_DIR}"
    fi

    if [ -n "$MAKE_TEST" ];then
         succ_msg "Begin to test ${SRC_DIR} ......"
         sleep 3
         eval $MAKE_TEST && succ_msg "Success to test ${SRC_DIR}"
    fi

    if [ -n "$INSTALL" ];then
        succ_msg "Begin to INSTALL ${SRC_DIR} ......"
        sleep 3
        eval $INSTALL && succ_msg "Success to install ${SRC_DIR}" || fail_msg "Failed to install ${SRC_DIR}"
    fi

    if [ -n "$SYMLINK" ];then
        succ_msg "Check and Create $SYMLINK"
        [ -L "$SYMLINK" ] && rm -f "$SYMLINK"
        ln -sf ${INST_DIR}/${SRC_DIR} "$SYMLINK"
    fi
    
    succ_msg "Strip files"
    [ -d "${INST_DIR}/${SRC_DIR}/bin"    ] && strip ${INST_DIR}/${SRC_DIR}/bin/* > /dev/null 2>&1
    [ -d "${INST_DIR}/${SRC_DIR}/sbin"   ] && strip ${INST_DIR}/${SRC_DIR}/sbin/* > /dev/null 2>&1
    [ -d "${INST_DIR}/${SRC_DIR}/lib"    ] && find  ${INST_DIR}/${SRC_DIR}/lib/ -iregex '.*\.so' | xargs strip > /dev/null 2>&1
    [ -d "${INST_DIR}/${SRC_DIR}/lib64"  ] && find  ${INST_DIR}/${SRC_DIR}/lib64/ -iregex '.*\.so' | xargs strip > /dev/null 2>&1
    succ_msg "Finish strip files"
   
    succ_msg "Clean old dir : ${STORE_DIR}/${SRC_DIR}" 
    cd ${STORE_DIR} && rm -rf "${STORE_DIR}/${SRC_DIR}"

    unset PRE_CONFIG CONFIG MAKE MAKE_TEST INSTALL SYMLINK LDFLAGS CPPFLAGS
}

## process running watch
proc_exist(){
    unset PROC_FOUND
    local PROC_NAME=$1
    PROC_PID=$(pgrep -P 1 ${PROC_NAME})

    if [ -z ${PROC_PID} ];then
        PROC_FOUND=0
    else
        PROC_FOUND=1
    fi
    
    #if [ ${PROC_NAME} = 'nginx' ];then
    #    HTTP_PORT_USE=$(netstat -nlp | grep ':80 ')
    #    if [ -z "${HTTP_PORT_USE}" ];then
    #        PROC_FOUND=0
    #    else
    #        PROC_FOUND=1
    #    fi
    #fi
}

## process user input and determine Yes or No.
# $1(USER_PROMPT): The phrase that prompt user.
# $2(DEFAULT_YN): The default value. Only y and n is available.
# Example: y_or_n 'Are you sure?' 'y'
function y_or_n(){
    unset USER_PROMPT DEFAULT_YN LOOP_SW USER_INPUT
    local USER_PROMPT=$1
    local DEFAULT_YN=$2
    local LOOP_SW=0
    while [ ${LOOP_SW} -eq 0 ]; do
        read -p "${USER_PROMPT}(y/n)[${DEFAULT_YN}]" USER_INPUT
        if [ "${USER_INPUT}" = 'y' ] || [ "${USER_INPUT}" = 'Y' ];then
            USER_INPUT=y
            LOOP_SW=1
        elif [ "${USER_INPUT}" = 'n' ] || [ "${USER_INPUT}" = 'N' ];then
            USER_INPUT=n
            LOOP_SW=1
        elif [ -z "${USER_INPUT}" ];then
            USER_INPUT=${DEFAULT_YN}
            LOOP_SW=1
        else
            warn_msg "You can only input y or n."
            LOOP_SW=0
        fi
    done
}
