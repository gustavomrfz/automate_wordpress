#!/bin/bash

# function: iferror
# produces an exit code 1 with message
function iferror {
  if [[ $? -eq 1 ]]; then
    echo $1; exit 1;
  fi
}

# function: mount_remote_backups
# mmount remote backup for a domain

function mount_remote_backup {
  mnt_dir=/tmp/$RANDOM;
  mkdir $mnt_dir
  scp -r $backup_user@$backup_host:$backup_remote_dir/$domain/* $mnt_dir
  sleep 1
  set_file_paths

}

# function: set_file_paths
# set last Wordpress files packges

function set_file_paths {

  wp_gz_file=$(find $mnt_dir -type f  -name "*.tar.gz" | sort  -rn | head -1);
  sql_gz_file=$(find $mnt_dir -type f -name "*.sql.gz" | sort -rn | head -1);
  nginx_file=$(find $mnt_dir -type f -name "*.conf");
  set_config_parameters
}

# function: read_root_path
# read root path from Nginx server configuration

function read_root_path {

  domain_string_length=${#domain}
  name_offset=$(($domaing_string_length  + 1 ))

  if [[ -e $nginx_file ]];then
    wp_path=$(grep -E "root.*$domain" $nginx_file \
    | awk -v offset=$name_offset -F' ' '{print substr($2, 1, length($2) - offset)}')
  else
    iferror "Site root is not available";
  fi
}

# function: restore_files
# extract files to local root

function restore_files {
 read_root_path
 tar -zxf $wp_gz_file -C $wp_path/.
 echo "Wordpress files now are restored"

}

#function: set_config_parameters
# get wp-config dabase parameters

function set_config_parameters {

 restore_files && wp_cnf=$wp_path/wp-config.php

 db_name=$(grep "DB_NAME" $wp_cnf | awk -F"'" '{print $4}');
 db_user=$(grep "DB_USER" $wp_cnf | awk -F"'" '{print $4}');
 db_password=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}');
 db_host=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}');

 if [[ $db_host == '' ]]; then
   db_host=localhost;
 fi
 restore_database
}



# function: restore_database
# restores database and tables to Mariadb/mysql_root_pass

function restore_database {

  zcat $sql_gz_file > /tmp/$domain.sql
  sql="/tmp/$domain.sql"
  mysql -u$db_user -p$db_password -e "create database if not exists $db_name;" \
  && mysql -u$db_user -p$db_password $db_name < $sql \
  || iferror "Datase not imported"
  echo "Database now is restored"
}


# function: nginx_disable_server
# disable server to restore

function nginx_disable_server {
  if [[ -e /etc/nginx/sites-enables/$domain.conf ]]; then
  	rm -f /etc/nginx/sites-enabled/$domain.conf;
  	systemctl reload nginx;
  fi
  echo "Server $domain disabled"

}
# function: nginx_enable_server
# enable again with resotred server

function nginx_enable_server {
  #if [[ -e /etc/nginx/sites-available/$domain.conf ]]; then
  #  mv -f /etc/nginx/sites-available ~/.;
  #fi
  cp -fp $mnt_dir/$domain.conf /etc/nginx/sites-available/$domain.conf \
  && ln -fs /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
  systemctl reload nginx
  echo "Server $domain enabled"

}


# function: start
# start to run scrip

function start {
  nginx_disable_server \
  && mount_remote_backup \
  && nginx_enable_server
}

if [[ -e ./params/restore.conf ]];then
  source ./params/restore.conf;
else
  iferror "First you need configure parameters";
fi

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

start
