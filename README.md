# Atomate Wordpress

# Scripts for automating tasks related to Wordpress

These **Bash scripts** automate some usual tasks working with **Wordpress**, and **Nginx**/**MariaDB** backend. The scripts are usefull on a clean Debian Jessie installation  and surely they don't work on Ubuntu so far. It's advise to **not** install before an Apache or other HTTP server, unless they are listening at any port except port 80, so they could may cause conflicts with Nginx.  

## Install one local instance

Install a Wordpress instance on local.  

### Usage

First change mod permissions of file to execute script, then:

`./install_wordpress.sh`

### Parameters

Some parameters are needed. They must be defined in `/conf/config` file.

###### Domain for Wordpress
`domain=`

###### Title for Wordpress
`title=`

###### Mysql root password
`mysql_root_pass=`

###### Install path (without final slash)
`wp_path=`

###### Charset that will use Wordpress
`wp_charset=`

##### Wordpress locales
`wp_locale=`

###### Wordpress user with administration rights
`wp_admin_user=`

###### Password for Wordpress administrator
`wp_admin_password=`

###### Wordpress administrator email
`wp_admin_email=``

###### Host of Mariadb
`wp_db_host=``

###### Database user for Wordpress
`wp_db_user=`
`
###### Database user for Wordpress password
`wp_db_password=`
  `
###### Name of database for Wordpress
`wp_db_name=`

###### User for wp cli. It's needed to execute wp cli.
`wpcli_user=`


## Uninstall one local instance

Uninstall local Wordpress installed with the **above** script. It's more than probable that script weren't work in other cases.

#### Usage

Simply:

`./uninstall_wordpress.sh yourdomain.org`

Only a FQDN domain name is needed as parameter. Script takes the rest of parameters, such the database name, from `wp-config.php`  and Nginx's available sites.

## Backup Wordpress

Backup database, files and Nginx's site configuration via SSH to a remote folder. A pair of SSH keys is highly recommended. If you need some help to create them, this [tutorial](https://debian-administration.org/article/530/SSH_with_authentication_key_instead_of_password) is a good first step.

### Usage

`./backup_wordpress.sh`

### Parameters

Defined in /params/backup.conf

###### FQDN to backup
 `domain=`
###### Remote user for SSH

`backup_user=`

###### Remote host (IP or domain name)
`backup_host=`

###### Remote path where files will be stored
`backup_remote_dir=`
