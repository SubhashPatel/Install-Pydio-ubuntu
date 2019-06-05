#!/bin/bash

# NextCloud Installation Script for Ubuntu
# with SSL certificate provided by Let's Encrypt (letsencrypt.org)
# Author: Subhash (serverkaka.com)

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

read -p 'db_root_password [secretpasswd]: ' db_root_password
read -p 'db_user_password [passwd]: ' db_user_password
echo

# Check All variable have a value
if [ -z $db_root_password ] || [ -z $db_user_password ]
then
      echo run script again please insert all value. do not miss any value
else
    
# Update System
apt-get update

# Install Apache
apt-get install apache2 -y

# Disable directory listing
sudo sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf

# Install PHP
sudo apt-get install php libapache2-mod-php php-common libapache2-mod-php php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl -y

# Install MySQL database server
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $db_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $db_root_password"
apt-get install mysql-server php-mysql -y

# Configure MySQL database
mysql -uroot -p$db_root_password <<QUERY_INPUT
CREATE DATABASE pydio;
CREATE USER 'pydio'@'localhost' IDENTIFIED BY '$db_user_password';
GRANT ALL PRIVILEGES ON pydio.* TO pydio@localhost;
FLUSH PRIVILEGES;
EXIT
QUERY_INPUT

# Enable Apache extensions
a2enmod proxy_fcgi setenvif
a2enconf php-fpm
service apache2 reload
a2enmod rewrite
service apache2 reload

# Download pydio
sudo apt update
sudo apt -y install apt-transport-https
sudo sh -c 'echo "deb https://download.pydio.com/pub/linux/debian/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/pydio.list'
wget -qO - https://download.pydio.com/pub/linux/debian/key/pubkey | sudo apt-key add -
printf "\n"
sudo apt update
sudo apt install pydio pydio-all php-xml -y

printf "\n\nInstallation complete.\n"
fi
