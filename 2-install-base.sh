#!/bin/bash

echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
apt-get update
apt-get -y upgrade

# Keep upstart from complaining
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

# Basic Requirements
apt-get -y install \
mysql-server \
mysql-client \
nginx \
php5-fpm \
php5-mysql \
php-apc \
pwgen \
python-setuptools \
curl \
git \
unzip \
cron-apt

# Wordpress Requirements
apt-get -y install \
php5-curl \
php5-gd \
php5-intl \
php-pear \
php5-imagick \
php5-imap \
php5-mcrypt \
php5-memcache \
php5-ming \
php5-ps \
php5-pspell \
php5-recode \
php5-snmp \
php5-sqlite \
php5-tidy \
php5-xmlrpc \
php5-xsl

# mysql config
sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# nginx config
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
# ADD ./nginx-site.conf /etc/nginx/sites-available/default

# Supervisor Config
/usr/bin/easy_install supervisor
# ADD ./supervisord.conf /etc/supervisord.conf

# Install Wordpress
wget http://wordpress.org/latest.tar.gz 
mv latest.tar.gz /usr/share/nginx/
cd /usr/share/nginx/ && tar xvf latest.tar.gz && rm latest.tar.gz
mv /usr/share/nginx/wordpress /usr/share/nginx/www
chown -R www-data:www-data /usr/share/nginx/www

