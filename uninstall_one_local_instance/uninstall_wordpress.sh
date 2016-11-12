#!/bin/bash

domain=dominioC.org

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

 if [[ -e ./conf/config ]];then
 		source ./conf/config;
 else
        iferror "First you need configure parameters"
 fi


# function: read_root_path
# Read root path from Nginx server

function read_root_path {
    if [[ -e /etc/sites-available/$domain.conf ]];then
          wp_path=$(grep -E "root.*$domain" /etc/sites-available/$domain.conf \
          | awk -F' ' '{print substr($2, 1, length($2)-1)}');
    else
         iferror "Site is not available";
    fi
}

# function: get_config_parameters
# Read wp-conging.php to get parameters needed to uninstall

function get_config_parameters {
  wp_cnf=$wp_path/wp-config.php

  db_name=$(grep "DB_NAME" $wp_cnf | awk -F"'" '{print $4}')
  db_user=$(grep "DB_USER" $wp_cnf | awk -F"'" '{print $4}')
  db_password=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}')
  db_host=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}')
  if [ $db_host -eq '' ]; then
      db_host=localhost
}

# function: mysql_remove_database
# Remove database from mysql

function mysql_remove_database {
   SQL="drop database if exists $db_name";
   mysql -u$db_user -p$db_password -e $SQL || iferror "Database not removed";
}

# function: remove_root_path
# remove path of Wordpress installation

function remove_root_path {
  if [[ -d $wp_path ]]; then
    rm -rf $wp_path;
  else
    iferror "Root path does not exists"
  fi
}

# function: nginx_disable_site
# disable site from sites-enabled

function nginx_disable_site {
  if [[ -e /etc/nginx/sites-enabled/$domain.conf]]; then
      rm -f /etc/nginx/sites-enabled/$domain.conf;
  else
      iferror "Site is not enabled"
  fi
}

#function nginx_remove_site
# remove server from sites-available

function nginx_remove_site {
  if [[ -e /etc/nginx/sites-available/$domain.conf]]; then
      rm -f /etc/nginx/sites-available/$domain.conf;
  else
      iferror "Site is not available "
  fi
}

function start {
  read_root_path \
  && get_config_parameters \
  && mysql_remove_database \
  && remove_root_path \
  && nginx_disable_site \
  && nginx_remove_site
}

start
