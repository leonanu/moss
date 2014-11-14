#!/bin/bash
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
    echo -en "$COLOR $MSG $NORMAL\n"
}

succ_msg(){
    local MSG="$*"
    color_msg green $MSG
}

fail_msg(){
    local MSG="$*"
    color_msg red $MSG && exit 1
}

warn_msg(){
    local MSG="$*"
    color_msg yellow $MSG
}

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
            fail_msg "parse $SRC : Unkown format ${FILE_EXT}"
            ;;
    esac
}

get_file(){
    if [ ${PGM} == 'remote' ];then
        if [ ! -e "${STORE_DIR}/$SRC" ]; then
            wget -c -t10 -nH -T900 ${DOWN_URL}/$SRC -P ${STORE_DIR}
            if [ $? -eq 0 ]; then
                succ_msg "$SRC download OK!"
                sleep 1
            else
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
                    fail_msg "$SRC download Error!"
                fi
            fi
        fi
    fi
}

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
            fail_msg "unpack $SRC: Unknown package format!"
            ;;
    esac
}

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
