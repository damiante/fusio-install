#!/bin/bash
# This script adapted by Damian Testa to facilitate one-click Fusio install.
# Original comments includeded below
#--------------------------------------------------
# Script author: Danie Pham
# Script site: https://www.writebash.com
# Script date: 07-03-2019
# Script ver: 1.0
# Script use to install LEMP stack on Ubuntu 16.04
#--------------------------------------------------
# Software version:
# 1. OS: Ubuntu 16.04.5 LTS 64 bit
# 2. Nginx: 1.14.2
# 3. MariaDB: 10.3.13
# 4. PHP 7: 7.3.2-3+ubuntu16.04.1+deb.sury.org+1
#--------------------------------------------------
# List function:
# 1. f_check_root: check to make sure script can be run by user root
# 2. f_update_os: update all the packages
# 3. f_install_lemp: funtion to install LEMP stack
# 4. f_sub_main: function use to call the main part of installation
# 5. f_main: the main function, add your functions to this place

# Function check user root
f_check_root () {
    if (( $EUID == 0 )); then
        # If user is root, continue to function f_sub_main
        return true
    else
        # If user not is root, print message and exit script
        echo "Please run this script by user root !"
        exit
    fi
}

# Function update os
f_update_os () {
    echo "Starting update os ..."
    echo ""
    sleep 1
    apt-get update
    apt-get upgrade -y
    echo ""
    sleep 1
}

# Function install LEMP stack
f_install_lemp () {
    ########## INSTALL NGINX ##########
    echo "Start install nginx ..."
    echo ""
    sleep 1

    # Add Nginx's repository to server Ubuntu 16
    echo "Add Nginx's repository to server ..."
    echo ""
    sleep 1
    echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list
    echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list

    # Download and add Nginx key
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

    # Update new packages from Nginx repo
    echo ""
    echo "Update new packages from Nginx's repository ..."
    echo ""
    sleep 1
    apt update

    # Install and start nginx
    echo ""
    echo "Installing nginx ..."
    echo ""
    sleep 1
    apt install nginx -y
    systemctl enable nginx && systemctl start nginx
    echo ""
    sleep 1

    ########## INSTALL MARIADB ##########
    echo "Start install MariaDB server ..."
    echo ""
    sleep 1

    # Add MariaDB's repository to server Ubuntu 16
    echo "Add MariaDB's repository to server ..."
    echo ""
    sleep 1
    apt install software-properties-common -y
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://mariadb.biz.net.id/repo/10.3/ubuntu xenial main'

    # Update new packages from MariaDB repo
    echo ""
    echo "Update new packages from MariaDB's repository ..."
    echo ""
    sleep 1
    apt update

    # Install MariaDB server
    echo "Installing MariaDB server ..."
    echo ""
    sleep 1
    apt install mariadb-server -y
    echo "What was the root MariaDB password you chose?"
    read -sp 'Password: ' passvar
    systemctl enable mysql && systemctl start mysql
    mysql -u root -p $passvar -e "create database fusio;"
    echo "Fusio database created"
    echo ""
    sleep 1

    ########## INSTALL PHP7 ##########
    # This is unofficial repository, it's up to you if you want to use it.
    echo "Add repository PHP 7 ..."
    echo ""
    sleep 1

    # Add unofficial repository PHP 7.3 to server Debian 8
    apt install software-properties-common python-software-properties -y
    add-apt-repository ppa:ondrej/php
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

    echo "Update packages from Dotdeb repository ..."
    echo ""
    sleep 1
    apt update
    echo ""
    sleep 1

    echo "Start install PHP 7 ..."
    echo ""
    sleep 1
    apt install php7.3 php7.3-cli php7.3-common php7.3-fpm php7.3-gd php7.3-mysql php7.3-xml php7.3-soap -y
    echo ""
    sleep 1

    # Config to make PHP-FPM working with Nginx
    echo "Config to make PHP-FPM working with Nginx ..."
    echo ""
    sleep 1
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' /etc/php/7.3/fpm/php.ini
    sed -i 's:user = www-data:user = nginx:g' /etc/php/7.3/fpm/pool.d/www.conf
    sed -i 's:group = www-data:group = nginx:g' /etc/php/7.3/fpm/pool.d/www.conf
    sed -i 's:listen.owner = www-data:listen.owner = nginx:g' /etc/php/7.3/fpm/pool.d/www.conf
    sed -i 's:listen.group = www-data:listen.group = nginx:g' /etc/php/7.3/fpm/pool.d/www.conf
    sed -i 's:;listen.mode = 0660:listen.mode = 0660:g' /etc/php/7.3/fpm/pool.d/www.conf

    # Create web root directory and php info file
    #echo "Create web root directory and PHP info file ..."
    #echo ""
    #sleep 1
    #mkdir /etc/nginx/html
    #echo "<?php phpinfo(); ?>" > /etc/nginx/html/info.php
    #chown -R nginx:nginx /etc/nginx/html

    # Create demo nginx vhost config file
    echo "Create demo Nginx vHost config file ..."
    echo ""
    sleep 1
    cat > /etc/nginx/conf.d/default.conf <<"EOF"
server {
    listen 80;
    listen [::]:80;

    root /var/www;
    index index.php index.html index.htm;

    server_name localhost;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include         fastcgi_params;
        fastcgi_pass    unix:/run/php/php7.3-fpm.sock;
        fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index   index.php;
    }
}
EOF

    # Install Composer and Fusio
    echo "Installing Composer..."
    echo ""
    apt install composer

    echo "Installing Fusio..."
    echo ""
    mkdir /var/www/fusio
    wget -P /var/www/fusio https://github.com/apioo/fusio/releases/download/v1.7.0/fusio_1.7.0.zip
    unzip /var/www/fusio/fusio_1.7.0.zip -d /var/www/fusio
    chown -R nginx:nginx /var/www/fusio
    chmod -r 755 /var/www/fusio
    rm /var/www/fusio/fusio_1.7.0.zip /var/www/fusio/composer.lock
    cd /var/www/fusio
    composer install
    php /var/www/fusio/bin/fusio install
    php /var/www/fusio/bin/fusio adduser


    # Restart nginx and php-fpm
    echo "Restart Nginx & PHP-FPM ..."
    echo ""
    sleep 1
    systemctl restart nginx
    systemctl restart php7.3-fpm

    echo "Done!"
    #echo "You can access http://YOUR-SERVER-IP/info.php to see more informations about PHP"
    sleep 1
}

# The sub main function, use to call neccessary functions of installation
f_sub_main () {
    #f_update_os
    f_install_lemp
}

# The main function
f_main () {
    f_check_root
    f_sub_main
}
f_main

exit
