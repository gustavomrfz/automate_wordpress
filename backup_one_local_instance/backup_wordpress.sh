#!/bin/bash


# function: iferror
# produces an exit code 1 with message
function iferror {
	if [[ $? -eq 1 ]]; then
		echo $1; exit 1;
	fi
}

# function: read_root_path
# Read root path from Nginx server

function read_root_path {
    if [[ -e /etc/nginx/sites-available/$domain.conf ]];then
          wp_path=$(grep -E "root.*$domain" /etc/nginx/sites-available/$domain.conf \
          | awk -F' ' '{print substr($2, 1, length($2)-1)}');
    else
         iferror "Site is not available";
    fi
}

# function: get_config_parameters
# Read wp-conging.php to get parameters

function get_config_parameters {

  wp_cnf=$wp_path/wp-config.php;
  db_name=$(grep "DB_NAME" $wp_cnf | awk -F"'" '{print $4}');
  db_user=$(grep "DB_USER" $wp_cnf | awk -F"'" '{print $4}');
  db_password=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}');
  db_host=$(grep "DB_PASSWORD" $wp_cnf | awk -F"'" '{print $4}');
  if [[ $db_host == '' ]]; then
      db_host=localhost;
  fi
}

# function: mysql_dump
# Produces a backup of full database in a tar.gz file

function mysql_dump {
   ssh $backup_user@$backup_host "mkdir -p $backup_remote_dir/$domain"
  mysqldump --user $db_user --password=$db_password  \
  $db_name | gzip -c | ssh $backup_user@$backup_host "cat > \
  $backup_remote_dir/$domain/$(date +%Y%m%d)$db_name.sql.gz" \
  || iferror "Backup for database named $db_name has failed" \
  && wp_simple_backup_files;
}
# function: wp_simple_backup_files
# Produces a tar.gz to a remote host

function wp_simple_backup_files {
  wp_targz="/tmp/$(date +%Y%m%d)$domain.tar.gz";
  if [[ -d $wp_path ]]; then
    tar czfp $wp_targz -C $wp_path . \
    && scp $wp_targz $backup_user@$backup_host:$backup_remote_dir/$domain/. \
    && rm -f $targz_file \
    || iferror "Backup file not sended to $backup_host"
  fi
}
# function: nginx_site_backup
# Produces a file with Nginx configurarion of the given server

function nginx_site_backup {
  if [[ -e /etc/nginx/sites-enabled/$domain.conf ]]; then
    scp /etc/nginx/sites-enabled/$domain.conf \
    $backup_user@$backup_host:$backup_remote_dir/$domain/.
  fi
}

function start {
 read_root_path \
 && get_config_parameters \
 && mysql_dump \
 && nginx_site_backup
}

if [[ -e ./params/backup.conf ]];then
 		source ./params/backup.conf;
else
    iferror "First you need configure parameters";
fi

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
start
