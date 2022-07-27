#!/bin/bash
#start script with sudo



echo "---------------Start program to install LEMP + Wordpress----------(Nginx(latest);php-fpm(7.4);Mariadb(latest))--------"
sleep 1
echo " Starting installation  nginx ......"
sleep 2 
sudo apt update -y
sudo apt install nginx -y
echo "-------------------------------------------------------------Check ....--------------------------------------------------"
function check_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx already installed !"
  else
        echo "Nginx not installed"
        sleep 1
echo "Do u want reinstall ? y or no"
read  yes
if  [ $yes == "y" ]; then
        echo "Installing nginx..."
        sudo apt update -y
        sudo apt install nginx -y
        check_nginx
fi
  fi
}
#call nginx
check_nginx
echo "-------Nginx installation ended--------- "
echo "" 
echo "" 
echo "" 
echo " Starting installation php-fpm ......"
sleep 2 
sudo apt update -y
sudo apt install -y python-software-properties
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update -y
sudo apt-get install php7.4-fpm php7.4-cli php7.4-mysql php7.4-curl php7.4-json -y
echo "-------------------------------------------------------------Check ....--------------------------------------------------"
sleep 2
function check_php-fpm(){
  if [ -x "$(command -v php)" ]; then
      echo "Php-fpm already installed !"
  else
        echo "Php-fpm not installed"
        sleep 1
echo "Do u want reinstall ? y or no"
read  yes
if  [ $yes == "y" ]; then
        echo "Installing php-fpm..."
        sudo apt update -y
	apt-get install php7.4 php7.4-fpm php7.4-cli php7.4-mysql php7.4-curl php7.4-json -y
        check_php-fpm
fi
  fi
}

check_php-fpm
echo "--------Php-Fpm installation ended----------"
echo ""
echo ""
echo ""
echo " Starting installation mysql ......" 
sudo apt update
sudo apt install -y mariadb-server
sudo mysql_secure_installation
echo "--------Mysql installation ended----------"
echo ""
echo ""
echo ""
echo "-------------------Start setting all services--------------------"
sleep 2
echo "---------------------------------Setting php-fpm...--------------------------------------------"

sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = \/run\/php\/php-fpm.sock/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.4/fpm/php.ini
sed -i 's/user = www-data/user = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/listen.owner = www-data/listen.owner = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/listen.group = www-data/listen.group = nginx/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php/7.4/fpm/pool.d/www.conf
sudo useradd nginx
sudo chown -R root:nginx /var/lib/php
echo "----------------------------------------Setting nginx ....---------------------------------------"
sleep 1
#sed -i  's/listen [::]:80;/server_name 192.168.1.104;/g'
#sed -i  's/server_name _;/#server_name _;/g'
#sed -i 's/root \/var\/www\/html;/root \/wordpress;/g' /etc/nginx/sites-enabled/default
#sed -i 's/user www-data;/user nginx;/g' /etc/nginx/nginx.conf 
#sed -i '46a\\t\location ~ \\.php$ { \n\t\ fastcgi_pass unix:/run/php/php-fpm.sock; \n\}' /etc/nginx/sites-enabled/default
sudo rm -rf /etc/nginx/sites-enabled/default
cat <<EOF > /etc/nginx/sites-enabled/default.conf

server{

        listen 80;
        server_name 192.168.1.104;
        root /wordpress;
        index index.php index.html;


location ~ \.php$ {
include fastcgi_params;
 try_files $uri =404;
 fastcgi_index   index.php;
fastcgi_cache microcache;
fastcgi_cache_valid 200 60m;
fastcgi_cache_bypass $no_cache;
fastcgi_no_cache $no_cache;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
fastcgi_pass unix:/run/php-fpm/www.sock;

        }

location ~ \.mp4$ {
root /wordpress;
auth_basic "Restricted Content";
auth_basic_user_file /etc/nginx/.htpassw;

mp4;
mp4_buffer_size 4M;
mp4_max_buffer_size 10M;

        }


}

EOF

echo "------------------------Checking setting configuration....-------------------------------"
if out=$(nginx -t 2>&1); then
    echo "success"
        else
    echo "failure, because: $out"
fi
echo "Disable ufw...."
sudo ufw status verbose
sudo ufw disable
echo " Activating all services ....."
sudo systemctl start nginx
sleep 1
sudo systemctl enable nginx
echo  "nginx active"
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm 
echo "php-fpm active ...."

echo "----------------------------------------Setting MariaDB...---------------------------------------"
PASSWDDB="!Wpuser"
# replace "-" with "_" for database username
MAINDB="wordpress"
DBUSER="wp_user"

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then

    mysql -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${DBUSER}'@'192.168.1.104';"
    mysql -e "FLUSH PRIVILEGES;"

# If /root/.my.cnf doesn't exist then it'll ask for root password   
else
    echo "Please enter root user MySQL password!"
    echo "Note: password will be hidden when typing"
    read -p rootpasswd
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${DBUSER}'@'192.168.1.104';"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
fi

sudo systemctl start  mariadb
sudo systemctl enable mariadb
echo "MariaDB active ...."
echo "------All services active-------"


echo "--------------------------------Start install and setting WORDPRESS-------------------------------------------------"


sudo mkdir  /wordpress
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv  wordpress/* /wordpress
sudo chown nginx: /wordpress/
sudo chmod -R 777 /wordpress/wp-content
cd /wordpress/

#Copy the content of WP Salts page
#WPSalts=$(wget https://api.wordpress.org/secret-key/1.1/salt/ -q -O -)

#Add the following PHP code inside wp-config
#cat <<EOF > wp-config-sample.php
#<?php

#define('DB_NAME', 'wordpress');
#define('DB_USER', 'wp_user');
#define('DB_PASSWORD', '!Wpuser');
#define('DB_HOST', '192.168.1.104');
#define('DB_CHARSET', 'utf8');
#define('DB_COLLATE', '');
#define('FS_METHOD', 'direct');


#${WPSalts}
#EOF

#Now that we are good, let's rename the wp-config sample
#mv wp-config-sample.php wp-config.php

chmod 660 wp-config.php

#Just to be sure, let's fix files and directories permissions
sudo find . -type f -exec chmod 644 {} +
sudo find . -type d -exec chmod 755 {} +
sudo chown -R nginx:nginx *

#Fancy message with colored background
echo "$(tput setaf 7)$(tput setab 6)---|-WP READY TO ROCK-|---$(tput sgr 0)"

sudo systemctl restart nginx

