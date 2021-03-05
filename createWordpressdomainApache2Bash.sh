#!/bin/bash

#check if script is runned by root 
if [[ `id -u` != 0 ]]; then
    echo >&2 "Must be root to run script";
    exit;
fi

echo "-----------------------------------------------------"
echo "STEP #1/7";

#read domain name from user 
read -p "DOMANIN_NAME: [ex:my-site.xyz] " DOMAIN_NAME;


DB_USER_NAME=$(cat /dev/urandom | tr -cd 'a-f' | head -c 12)
DB_USER_PASS=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32)
DB_NAME=$(cat /dev/urandom | tr -cd 'a-f' | head -c 32)



if [[ $DOMAIN_NAME == "" ]]; then
    echo >&2 "DOMAIN_NAME is empty";
    exit;
fi


echo "-----------------------------------------------------"
echo "STEP #2/7 (make directories and set permissions)"
if ! mkdir -p /var/localhttp/$DOMAIN_NAME; then
echo "Web directory already Exist !"
exit;
fi
chown -R www-data:www-data /var/localhttp/$DOMAIN_NAME;
chmod -R 755 /var/localhttp/$DOMAIN_NAME;



echo "-----------------------------------------------------"
echo "STEP #2/7 (download WP fro source)"
rm -rf /tmp/wordpress
cd /tmp
wget -c -q http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

echo "-----------------------------------------------------"
echo "STEP #3/7 (install WP)"
cp -a /tmp/wordpress/. /var/localhttp/$DOMAIN_NAME/
chown www-data:www-data -R /var/localhttp/$DOMAIN_NAME/*

mkdir /var/localhttp/$DOMAIN_NAME/wp-content/uploads
chmod 775 /var/localhttp/$DOMAIN_NAME/wp-content/uploads

echo "-----------------------------------------------------"
echo "STEP #4/7 (creaet and configure DB)"
#create vritual user and database 
mysql -e "CREATE DATABASE ${DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -e "CREATE USER ${DB_USER_NAME}@localhost IDENTIFIED BY '${DB_USER_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER_NAME}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"



echo "-----------------------------------------------------"
echo "STEP #5/7 (configure WP 'DB connection')"
#create wp-config.php and set information
cp /var/localhttp/$DOMAIN_NAME/wp-config-sample.php /var/localhttp/$DOMAIN_NAME/wp-config.php


sed -i -e "s/database_name_here/$DB_NAME/g" /var/localhttp/$DOMAIN_NAME/wp-config.php
sed -i -e "s/username_here/$DB_USER_NAME/g" /var/localhttp/$DOMAIN_NAME/wp-config.php
sed -i -e "s/password_here/$DB_USER_PASS/g" /var/localhttp/$DOMAIN_NAME/wp-config.php

echo "-----------------------------------------------------"
echo "STEP #6/7 (create apache2 virtual domain)"

cat << EOF > /etc/apache2/sites-available/$DOMAIN_NAME.conf

<VirtualHost $DOMAIN_NAME:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    DocumentRoot /var/localhttp/$DOMAIN_NAME

	ErrorLog    /var/localhttp/error.log
	CustomLog   /var/localhttp/access.log combined


    <Directory  '/var/localhttp/$DOMAIN_NAME'>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>
</VirtualHost>

EOF



echo "Allow Domain In /etc/hosts";
echo "127.0.0.1 $DOMAIN_NAME" >> /etc/hosts


echo "-----------------------------------------------------"
echo "STEP #7/7 (enable virtual domain)\n"
a2ensite $DOMAIN_NAME.conf
echo "RESTART Apache2 2"

service apache2 restart

cat <<EOF
====================WP CREATED SUCCESSFULLY!============================
URL:http://$DOMAIN_NAME/
DB USER NAME : $DB_USER_NAME
DB PASSWORD : $DB_USER_PASS
DB NAME : $DB_NAME
EOF
