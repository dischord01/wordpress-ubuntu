!#/bin/bash
##################
# NGINX CONF
##################
cp conf/nginx-site.conf /etc/nginx/sites-available/default
cp conf/supervisord.conf /etc/supervisord.conf
mkdir /etc/nginx/ssl

if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
  #mysql has to be started this way as it doesn't work to call from /etc/init.d
  /usr/bin/mysqld_safe & 
  sleep 10s
  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  WORDPRESS_DB="wordpress"
  MYSQL_PASSWORD=`pwgen -c -n -1 12`
  WORDPRESS_PASSWORD=`pwgen -c -n -1 12`
  #This is so the passwords show up in logs. 
  echo mysql root password: $MYSQL_PASSWORD
  echo wordpress password: $WORDPRESS_PASSWORD
  echo $MYSQL_PASSWORD > /mysql-root-pw.txt
  echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt

  sed -e "s/database_name_here/$WORDPRESS_DB/
  s/username_here/$WORDPRESS_DB/
  s/password_here/$WORDPRESS_PASSWORD/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

chown www-data:www-data /usr/share/nginx/www/wp-config.php

mysqladmin -u root password $MYSQL_PASSWORD 

mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"

killall mysqld
fi

############
# SSL Cert
############
openssl req -nodes -newkey rsa:2048 -nodes -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.csr -subj "/C=US/ST=Virginia/L=ALexandria/O=Arcwave/OU=Cloudworks/CN=wp.arcwaveusa.com"

############
# Composer
############
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

############
# WP Plugins
############
pushd /usr/share/nginx/www/wp-content/plugins
/usr/bin/wp core install --url="$WP_URL"  --title="$WP_BLOG_TITLE" --admin_user="$WP_BOSS" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_EMAIL"
/usr/bin/wp plugin install wp-mail-smtp cms-tree-page-view w3-total-cache wordpress-seo white-label-cms google-analyticator disqus-comment-system nginx-helper
# popd


# start all the services
/usr/local/bin/supervisord -n

