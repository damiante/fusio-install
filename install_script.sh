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
check_root () {
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
update_os () {
    echo "Starting update os ..."
    echo ""
    sleep 1
    apt-get update
    apt-get upgrade -y
    echo ""
    sleep 1
}

install_nginx (){
	
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
}

install_mariadb () {

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
    systemctl enable mysql && systemctl start mysql

}

fusio_mariadb_init () {

    # Initialise MariaDB for Fusio use
    mysql -u root -e "CREATE DATABASE fusio;
    CREATE USER $fusio_db_user;
    SET PASSWORD FOR $fusio_db_user = PASSWORD('$fusio_db_password');
    GRANT ALL ON fusio.* TO $fusio_db_user;
    FLUSH PRIVILIGES;"
    echo "Fusio database and user created"
    echo ""
    sleep 1
}

install_php7 () {

    ########## INSTALL PHP7 ##########
    # This is unofficial repository, it's up to you if you want to use it.
    echo "Add repository PHP 7 ..."
    echo ""
    sleep 1

    # Add unofficial repository PHP 7.3 to server Debian 8
    apt install software-properties-common python-software-properties -y
    add-apt-repository ppa:ondrej/php -y
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
}

dump_nginx_default_conf () {

    # Create demo nginx vhost config file
    echo "Create demo Nginx vHost config file ..."
    echo ""
    sleep 1
	rm /etc/nginx/conf.d/default.conf
    cat > /etc/nginx/conf.d/$fusio_app_url.conf <<"EOF"
server {
    listen 80;
    listen [::]:80;

    root /var/www/fusio;
    index index.php index.html index.htm;

    server_name localhost;

    location / {
        try_files $uri $uri/ /public/index.php$uri;
    }

    location ~ ^.+.php {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;

        set $path_info $fastcgi_path_info;
        fastcgi_param PATH_INFO $path_info;

        try_files $fastcgi_script_name =404;

        include         fastcgi_params;
        fastcgi_pass    unix:/run/php/php7.3-fpm.sock;
        fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index   index.php;
    }
}
EOF
}

configure_php_fpm_nginx () {

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

}

install_fusio () {

    # Install Composer and Fusio
    echo "Installing Composer..."
    echo ""
    apt install composer -y

    echo "Installing Fusio..."
    echo ""
    mkdir -p  /var/www/fusio
    wget -P /var/www/fusio https://github.com/apioo/fusio/releases/download/v1.9.0/fusio_1.9.0.zip 
	apt install unzip
    unzip /var/www/fusio/fusio_1.9.0.zip -d /var/www/fusio
    chown -R nginx:nginx /var/www/fusio
    chmod -R 755 /var/www/fusio
    rm /var/www/fusio/fusio_1.9.0.zip /var/www/fusio/composer.lock
    cd /var/www/fusio
    composer install
    printf "y" | php /var/www/fusio/bin/fusio install
    php /var/www/fusio/bin/fusio adduser -s 1 -u $fusio_user -e $fusio_email -p $fusio_password

    sed -i "s/FUSIO_URL=.*/FUSIO_URL=\"http:\/\/localhost\/public\"/" /var/www/fusio/.env
    sed -i "s/FUSIO_DB_USER=.*/FUSIO_DB_USER=\"$fusio_db_user\"/" /var/www/fusio/.env
    sed -i "s/FUSIO_DB_PW=.*/FUSIO_DB_PW=\"$fusio_db_password\"/" /var/www/fusio/.env
    chmod -R 777 /var/www/fusio/cache
}

restart_lemp_services () {

    # Restart nginx and php-fpm
    echo "Restart Nginx & PHP-FPM ..."
    echo ""
    sleep 1
    systemctl restart nginx
    systemctl restart php7.3-fpm
    systemctl restart mysql

}

# Function install LEMP stack
install_lemp_fusio () {

    install_nginx

    install_mariadb
    fusio_mariadb_init

    install_php7

    configure_php_fpm_nginx 
    dump_nginx_default_conf    

    install_fusio
    
    restart_lemp_services
	
	this_machine_ip=$(ip route get 1 | awk '{print $NF;exit}')

    echo "Done! Your Fusio instance is available at http://"$this_machine_ip"/public/fusio"
    sleep 1
}

# The sub main function, use to call neccessary functions of installation
do_fusio_install () {
    update_os
    fusio_db_user="fusio_admin"
    fusio_db_password="fusio_password"
	fusio_user="admin"
	fusio_password="admin123"
	fusio_email="test@example.com"
	fusio_app_url="api.example.com"
    install_lemp_fusio

}


# The main function
main () {
    check_root
    do_fusio_install
}

main

exit
