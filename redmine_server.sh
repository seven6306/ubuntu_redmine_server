#!/bin/bash
# Script for ubuntu 14.04 LTS

MYSQL_PASS=123456
REDMINE_PASS=123456
REDMINE_SERVER_NAME=www.dqaredmine.com
REDMINE_SERVER_ADMIN=blake.liou@vivotek.com

apt-get update -y
apt-get install -y apache2 libapache2-mod-passenger
cat << EOF | debconf-set-selections
mysql-server mysql-server/root_password password $MYSQL_PASS
mysql-server mysql-server/root_password_again password $MYSQL_PASS
EOF
apt-get install -y mysql-server mysql-client
cat << EOF | debconf-set-selections
redmine redmine/instances/default/dbconfig-install boolean true
redmine redmine/instances/default/database-type select mysql
redmine redmine/instances/default/mysql/admin-pass password $MYSQL_PASS
redmine redmine/instances/default/password-confirm password $MYSQL_PASS
redmine redmine/instances/default/mysql/app-pass password $REDMINE_PASS
redmine redmine/instances/default/app-password-confirm password $REDMINE_PASS
EOF
apt-get install -y redmine redmine-mysql

cat << EOF | tee /etc/apache2/mods-available/passenger.conf
<IfModule mod_passenger.c>
  PassengerDefaultUser www-data
  PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
  PassengerDefaultRuby /usr/bin/ruby
</IfModule>
EOF
ln -s /usr/share/redmine/public /var/www/redmine
gem install bundler

cat 000-default.conf | tee /etc/apache2/sites-available/000-default.conf
sed -i "s,<REDMINE_SERVER_NAME>,$REDMINE_SERVER_NAME,g" /etc/apache2/sites-available/000-default.conf
sed -i "s,<REDMINE_SERVER_ADMIN>,$REDMINE_SERVER_ADMIN,g" /etc/apache2/sites-available/000-default.conf

chown -R www-data:www-data /usr/share/redmine/
service apache2 restart
