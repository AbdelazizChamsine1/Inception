#!/bin/bash

    mkdir /var/www/
    mkdir /var/www/html

    cd /var/www/html

    # Install WordPress commands line tool

    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 

    chmod +x wp-cli.phar 
    mv wp-cli.phar /usr/local/bin/wp
    
    # Wait for MariaDB to be ready
    until mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1" > /dev/null 2>&1; do
        echo "Waiting for MariaDB to be ready..."
        sleep 3
    done
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php using wp-cli instead of sed
    wp config create --dbname=$MYSQL_DATABASE \
                     --dbuser=$MYSQL_USER \
                     --dbpass=$MYSQL_PASSWORD \
                     --dbhost=mariadb:3306 \
                     --allow-root

    # Install WordPress with correct environment variables
    wp core install --url=https://$DOMAIN_NAME \
                    --title="$WP_TITLE" \
                    --admin_user=$WP_ADMIN_USER \
                    --admin_password=$WP_ADMIN_PASSWORD \
                    --admin_email=$WP_ADMIN_EMAIL \
                    --skip-email \
                    --allow-root

    # Create additional WordPress user
    wp user create $WP_USER $WP_USER_EMAIL \
                   --user_pass=$WP_USER_PASSWORD \
                   --role=author \
                   --allow-root

    # Update WordPress URLs for HTTPS
    wp option update home "https://$DOMAIN_NAME" --allow-root
    wp option update siteurl "https://$DOMAIN_NAME" --allow-root

    # Configure PHP-FPM
    sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf
    mkdir /run/php

    # Start PHP-FPM
    php-fpm7.4 -F