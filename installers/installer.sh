#!/bin/bash
#
#  FlamesPanel Automatic Installer v0.1 ALPHA
#  
#  FlamesPanel v2 (c) Andrew Hong. 2016
#  All rights reserved.
#


# Show warning

echo "Installation will begin in 15 seconds."
echo "Warning: Installing FlamesPanel will replace your kernel with one that is within the 3.10 branch."
echo "Also, the root user will be disabled and a user named 'admin' will be in its place."
echo "Please enter [CTRL+C] to abort the installation of FlamesPanel."
sleep 15

# Ask user for configuration options

clear
echo "Please enter a hostname that points to the current server's IP address."
read serverhostname
sleep 3
clear
echo "Please enter a password for the 'admin' user."
echo "REMEMBER: Only use alphanumeric characters."
read adminpass
MYSQLPWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sleep 3
clear

# Begin installation

echo "===================================================="
echo "=                                                  ="
echo "=               /-------------------/              ="
echo "=              /    _______________/               ="
echo "=             /    /                               ="
echo "=            /    /______________                  ="     
echo "=           /                   /                  ="
echo "=          /    /---------------                   ="
echo "=         /    /                                   ="
echo "=        /____/  lamesPanel v2                     =" 
echo "=                                                  ="
echo "=                                                  ="
echo "=                  INSTALLING...                   ="
echo "=                                                  ="
echo "===================================================="
sleep 3
cd /tmp
chmod 111 /home
mkdir -p /home/root/public_html
chmod -R 700 /home/root

yum install -y git

# Download FlamesPanel

git clone https://github.com/FlamesRunner/FlamesPanel-v2.git
cd /tmp/FlamesPanel-v2/

# Install pre-requisites

rpm -Uvh http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel -y install kernel-ml
yum install -y epel-release
yum install -y nano mysql-server crontab gcc gcc-c++ zip unzip openssl 

# Set MySQL root password

mysqladmin -u root password $MYSQLPWD

# Setup chroot environment

mkdir /systemroot
mkdir /systemroot/bin
mkdir /systemroot/sbin
cp /tmp/FlamesPanel-v2/chrootbin/* /systemroot/bin
cp /tmp/FlamesPanel-v2/chrootsbin/* /systemroot/sbin
mkdir -p /systemroot/dev/pts
mkdir -p /systemroot/home
mkdir -p /systemroot/var/lib/mysql
mkdir -p /systemroot/usr
mkdir -p /systemroot/dev
mkdir -p /systemroot/lib
mkdir -p /systemroot/lib64
mkdir -p /systemroot/tmp
mkdir -p /systemroot/proc
mkdir -p /systemroot/opt
mkdir -p /systemroot/var/spool/mail
mkdir -p /systemroot/var/spool/cron
mkdir -p /systemroot/var/run/utmp
mkdir -p /systemroot/etc
mkdir -p /usr/local/flamespanel
mount --bind /dev/pts /systemroot/dev/pts
mount --bind /home /systemroot/
mount --bind /var/lib/mysql /systemroot/var/lib/mysql
mount --bind /usr /systemroot/usr
mount --bind /dev /systemroot/dev
mount --bind /lib /systemroot/lib
mount --bind /lib64 /systemroot/lib64
mount --bind /tmp /systemroot/tmp
mount --bind /opt /systemroot/opt
mount --bind /var/spool/mail /systemroot/var/spool/mail
mount --bind /var/spool/cron /systemroot/var/spool/cron
mount --bind /var/run/utmp /systemroot/var/run/utmp
mount --bind /etc /systemroot/etc
mount -o remount,rw,hidepid=2 /systemroot/proc

# Set up startup script

cat << EOF >> /etc/rc.local
mount -o remount,rw,hidepid=2 /proc
mount --bind /dev/pts /systemroot/dev/pts
mount --bind /home /systemroot/
mount --bind /var/lib/mysql /systemroot/var/lib/mysql
mount --bind /usr /systemroot/usr
mount --bind /dev /systemroot/dev
mount --bind /lib /systemroot/lib
mount --bind /lib64 /systemroot/lib64
mount --bind /tmp /systemroot/tmp
mount --bind /opt /systemroot/opt
mount --bind /var/spool/mail /systemroot/var/spool/mail
mount --bind /var/spool/cron /systemroot/var/spool/cron
mount --bind /var/run/utmp /systemroot/var/run/utmp
mount --bind /etc /systemroot/etc
EOF


# Copy over bin/sbin files
cp /tmp/FlamesPanel-v2/bin/* /bin
cp /tmp/FlamesPanel-v2/sbin/* /sbin
cp /tmp/FlamesPanel-v2/usr/local/flamespanel/* /usr/local/flamespanel
cp /tmp/FlamesPanel-v2/chrootbin/* /systemroot/bin/
cp /tmp/FlamesPanel-v2/chrootsbin/* /systemroot/sbin
cp /tmp/FlamesPanel-v2/rootfiles/* /root

# Copy over control panel files
cp -R /tmp/FlamesPanel-v2/files/* /home/root/public_html/
cp /tmp/FlamesPanel-v2/packages/* /usr/src

# Compile Apache and PHP

cd /usr/src
unzip apache_pkg.zip 
cd /usr/src/httpd-2.4.16/
./configure --with-included-apr && make && make install
cp /usr/src/httpd-2.4.16/support/apachectl /usr/sbin/apachectl
chmod 755 /usr/sbin/apachectl
cd /usr/src
unzip php5.5_pkg.zip
cd /usr/src/php-5.5.30
./configure '--with-pear=/usr/lib/pear' '--with-gd' '--enable-libxml' '--with-pdo-mysql' '--with-mysqli' '--with-mysql' '--enable-mbstring' '--enable-zip' '--with-mcrypt' '--with-apxs2=/usr/local/apache2/bin/apxs' '--enable-maintainer-zts' '--with-curl'
make && make install

# Set up MySQL tables

mysql -uroot -p$MYSQLPWD 'create database root_sessions;'
mysql -uroot -p$MYSQLPWD root_sessions < /tmp/FlamesPanel-v2/sql.txt

# Creating special directories and configure system

mkdir /tmp/vhosts
touch /tmp/vhosts/newvhost.conf
chmod 000 /tmp/vhosts
chmod 000 /tmp/vhosts/newvhost.conf

# Setup SSHd

cat << EOFA >> /etc/ssh/sshd_config
Match Group vzuser
    ChrootDirectory /systemroot/
    AllowTCPForwarding no
    X11Forwarding no
EOFA

# Set up virtual host cron job

#write out current crontab
echo "*/5 * * * * /bin/bash /root/process-websites" > /tmp/cronjob
crontab /tmp/cronjob
rm -rf /tmp/cronjob

# Configure virtual host for FlamesPanel

mkdir -p /etc/httpd/conf.d
cat << EOF >> /etc/httpd/conf.d/0-def.conf
ServerName $serverhostname

<VirtualHost *:80>
        ServerName $serverhostname
        ServerAdmin admin@localhost
        DocumentRoot /home/root/public_html
        LogLevel debug
        ErrorLog /home/root/panel-error.log
        CustomLog /home/root/panel-access.log common
        DirectoryIndex index.php index.html
        AssignUserId root root
<Directory '/home/root/public_html'>
AllowOverride All
Order allow,deny
Allow from all
</Directory>
</VirtualHost>

EOF

cp /tmp/FlamesPanel-v2/config/* /etc/httpd/conf.d/
echo 'Include /etc/httpd/conf.d/*.conf' >> /usr/local/apache2/conf/httpd.conf

cat << EOFB >> /home/root/public_html/dashboard/config.php
<?php
$mysqlpassword = '$MYSQLPWD';
?>
EOFB

useradd -d /home/admin -m admin
chmod 700 /home/admin
echo -e "$adminpass\n$adminpass" | passwd admin
cat sudoers.new > /etc/sudoers
passwd -l root

clear
sleep 3
echo "Starting core FlamesPanel services..."

echo "Starting Apache..."
apachectl -k start
echo "Applying changes to the SSH daemon..."
service sshd restart
echo "Reloading MySQL..."
service mysqld restart
echo "Success!"
sleep 5
clear
echo "Cleaning up installation files..."
rm -rf /tmp/FlamesPanel-v2
sleep 3
echo "===================================================="
echo "=                                                  ="
echo "=               /-------------------/              ="
echo "=              /    _______________/               ="
echo "=             /    /                               ="
echo "=            /    /______________                  ="
echo "=           /                   /                  ="
echo "=          /    /---------------                   ="
echo "=         /    /                                   ="
echo "=        /____/  lamesPanel v2                     ="
echo "=                                                  ="
echo "=                                                  ="
echo "=                  INSTALLED!                      ="
echo "=                                                  ="
echo "===================================================="

echo "Please login at http://$serverhostname with the details:"
echo "Username: admin"
echo "Password: $adminpass"
