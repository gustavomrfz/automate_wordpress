#!/bin/bash

sudoers_root="root ALL=(ALL:ALL) ALL"
sudoers_wpcli="wpcli ALL=(www-data) NOPASSWD: /usr/local/bin/wp"

useradd $wpcli_user;

# function: start
# Install sudo if it is not and run script

function start {
	apt-get update && apt-get -y install sudo && set_php7_sources
}

# function: iferror
# produces an exit code 1 with message
function iferror {
	if [[ $? -eq 1 ]]; then
		echo $1; exit 1;
	fi
}

#function  set_php7_sources
# add php7 repository to sources.list

set_php7_sources() {
    if ! (grep -qs "dotdeb" /etc/apt/sources.list); then
        echo "deb http://packages.dotdeb.org jessie all" \
				 >> /etc/apt/sources.list;
    fi
    if ! [[ -e dotdeb.gpg ]]; then
        wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg;
    fi
    install_dependencies
}


# function: install_dependencies
# Install needed dependencies

function install_dependencies {
	apt-get -y install sudo mariadb-server mariadb-client \
	php7.0-mysql php7.0-fpm nginx nginx-extras php7.0 sshfs \
        && install_WP_cli \
        && if ! ( grep -qs $sudoers_root /etc/sudoers ); then
							echo $sudoers_root >> /etc/sudoers;
	   			fi
}


# function: create_database
# create wordpress data base in mardiadb

function create_database {
	mysql -uroot -p$mysql_root_pass -e "drop database if exists $wp_db_name; create \
  database $wp_db_name" \
    || iferror "Failed. Database not created";
}


# function: create_and_grant_user
# create user for wordpress and grant all privileges

function create_and_grant_user {
	mysql -uroot -p$mysql_root_pass -e " grant all privileges on $wp_db_name.* to \
	'$wp_db_user'@'localhost' identified by '$wp_db_password';"
}


# function: install_WP_cli
# Install command line interface for wordpress

function install_WP_cli {
	wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
		|| iferror "Failed. WP command line interface not installed.";
	chmod +x wp-cli.phar;
	mv wp-cli.phar /usr/local/bin/wp \
		|| iferror "Failed. /usr/local/bin/wp not created";
        if ! (grep -qs $sudoers_wpcli /etc/sudoers); then
        	echo $sudoers_wpcli >> /etc/sudoers
				fi
        install_WP
}


# function: install_WP version path()
# install wordpress version at a given path

function install_WP {
	prefix=wp$RANDOM;
	if ! $(sudo -u $wpcli_user -- wp core is-installed); then
		create_database;
		create_and_grant_user;

		mkdir -p $wp_path && chmod -R 777 $wp_path && chown -R \
		www-data:www-data $wp_path;

		sudo -u $wpcli_user -- wp core download --locale=$wp_locale \
		--path=$wp_path \
		|| iferror "Wordpress not downloaded";

		if [ -e $wp_path/wp-config.php ];  then
			rm $wp_path/wp-config.php;
		fi

		sudo -u $wpcli_user --  wp core config --dbname=$wp_db_name \
		--dbuser=$wp_db_user --dbpass=$wp_db_password --dbhost=$wp_host  \
		--dbprefix=$prefix --locale=$wp_locale --path=$wp_path \
		|| iferror "Wordpress not configured" ;

		sudo -u $wpcli_user -- wp core install \
		--url=$domain --title="$title" --path=$wp_path --admin_user=$wp_admin_user \
		--admin_password=$wp_admin_password --admin_email=$wp_admin_email \
    --path=$wp_path \
		|| iferror "Wordpress not installed";

		chmod -R 775 $wp_path;
		nginx_create_site
  fi
}


# function: nginx_create_site
# Configure site for nginx

function nginx_create_site {
	if [ -e ./nginx/nginx.available ]; then
		sed -e "s|ROOTPATH|$wp_path|g" \
		-e "s|DOMAIN|$domain|g" ./nginx/nginx.available > \
		/etc/nginx/sites-available/$domain.conf \
		|| iferror "Site not available";
	else
		iferror "nginx.available does not exists";
	fi
	nginx_enable_site
}


# function: nginx_enable_site
# Enable site in Nginx

function nginx_enable_site {
	if [[ -e /etc/nginx/sites-enabled/default ]]; then
		rm -f /etc/nginx/sites-enabled/default;
  fi
	if [[ -e /etc/nginx/sites-enabled/$domain ]]; then
				rm -f /etc/nginx/sites-enabled/$domain
	fi
	ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/. \
	|| iferror "sites-enabled/$domain not created";
	systemctl reload nginx;
}

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
if [[ -e ./conf/config ]];then
 		source ./conf/config;
else
        iferror "First you need configure parameters"
fi

start
