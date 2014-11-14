# Moss

Moss is an automatic services environment deploy system For CentOS.

You could set up a L.N.M.P based environment easily by Moss. Inlcude all features below:

* **Optimize** - Automatic optimize CentOS system. Change to faster YUM repository mirror, add EPEL repository mirror, optimize kernel TCP settings, vi improved, sudo policy, SSH optimize;
* **Security** - Turn off unused services, disable SSH password authentication, add users with SSH RSA keys accroding to user configuration;
* **Services** - Automatic install Nginx/PHP FastCGI/PECL modules(Redis, Memcache, Memcached, XCache, Xhprof)/MySQL/Percona Xtrabackup/Redis/Memcached/KeepAlived/Squid/Varnish/Zabbix ...;
* **Performance** - All serives were set to optimized settings, you could use it in production environment directly;
* **Maintenance** - User configure file support. Automatic set up database backup policy, logs rotate policy and all service were added to SysV service;
* **Develop** - You could develop Moss easily. All features in Moss were designed by modules, you can add or remove modules to fit your need;

## Install
* Configure: Edit configuration file in ./etc/moos.conf. Change settings to fit your need.
* Package Repository: Moss support both download packages from a repository and get from local directory(./src). Set in ./etc/moss.conf
* Install: Run ```./install {init|lb|cache|web|php|db|nosql|ntp|zagent} ```

## Support
Nanu (nanu@inanu.net)
