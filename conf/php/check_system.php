<?php
// Modify by adam.li@ismole.com at 2012-09-06 17:50
// retrive php server type
    $sapi_type = php_sapi_name();

// output $sapi_type
    if ( $sapi_type == 'cli' ) {

        echo "You are using $sapi_type\n";

    } elseif ( $sapi_type == 'fpm-fcgi' or $sapi_type == 'apache2handler' or $sapi_type == 'cli-server' )  {

        echo "You are using $sapi_type<br>";

    } else {

        echo "Could not recognise the mode : $sapi_type\n";
        exit;

    }

// color output function
    function succ_msg($message){

        global $sapi_type;

        if ( $sapi_type == 'cli' ) {
            echo "\033[1;40;32m$message\033[0m\n";

        } elseif ( $sapi_type == 'fpm-fcgi' or $sapi_type == 'apache2handler' or $sapi_type == 'cli-server' ) {
            echo "<font color='green'>$message</font><br>";

        } else {
            echo "Could not recognise the mode : $sapi_type\n";
            exit;
        }

    }

    function fail_msg($message){

        global $sapi_type;

        if ( $sapi_type == 'cli' ) {
            echo "\033[1;40;31m$message\033[0m\n";

        } elseif ( $sapi_type == 'fpm-fcgi' or $sapi_type == 'apache2handler' or $sapi_type == 'cli-server' ) {
            echo "<font color='red'>$message</font><br>";

        } else {
            echo "Could not recognise the mode : $sapi_type\n";
            exit;
        }

    }

// check php extension
    $arr_ext=array('curl','mysql','mysqli','pdo_mysql','apc','memcache','memcached','redis','sockets');
    foreach ($arr_ext as &$extension) {
        if (extension_loaded($extension)){
            succ_msg("extensions : $extension check ok");
        } else {
            fail_msg("extensions : $extension check fail,please check it.");
        }
    }

// check connections

    $mysql_link = mysql_connect('localhost', 'root', 'root');
    if (!$mysql_link) {
        fail_msg('Could not connect: ' . mysql_error());
    } else {
        succ_msg ('Mysql connect successfully.');
        mysql_close($mysql_link);
    }


    $memcache_link = memcache_connect('127.0.0.1', 11127);
    if (!$memcache_link) {
        fail_msg('Could not connect memcache.');
    } else {
        succ_msg ('Memcache connect successfully.');
        memcache_close($memcache_link);
    }
