#!/bin/bash
# Script for ubuntu 14.04 LTS
. lib/NetworkConnTest.sh
. lib/declare_variables.sh
PORT=80
PROTOCOL=http
REDMINE_SERVER_NAME=www.dqaredmine.com
REDMINE_SERVER_ADMIN=blake.liou@vivotek.com

configure_apache2()
{
    apt-get update -y
    apt-get install -y apache2 libapache2-mod-passenger
    cat << EOF | debconf-set-selections
mysql-server mysql-server/root_password password $MYSQL_PASS
mysql-server mysql-server/root_password_again password $MYSQL_PASS
EOF
    python lib/back_file.py '/etc/apache2/mods-available/passenger.conf,/etc/apache2/sites-available/000-default.conf'
    cat << EOF | tee /etc/apache2/mods-available/passenger.conf
<IfModule mod_passenger.c>
  PassengerDefaultUser www-data
  PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
  PassengerDefaultRuby /usr/bin/ruby
</IfModule>
EOF
    [ ! -f 000-default.conf ] && printf "${RED}ERROR: file 000-default.conf is lost.${NC}\n" && exit 1
    cat 000-default.conf | tee /etc/apache2/sites-available/000-default.conf
    sed -i "s,<REDMINE_SERVER_NAME>,$REDMINE_SERVER_NAME,g" /etc/apache2/sites-available/000-default.conf
    sed -i "s,<REDMINE_SERVER_ADMIN>,$REDMINE_SERVER_ADMIN,g" /etc/apache2/sites-available/000-default.conf
}
configure_mysql()
{
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
    ln -s /usr/share/redmine/public /var/www/redmine
    gem install bundler
    chown -R www-data:www-data /usr/share/redmine/
}
# main
python lib/checkPermission.py || exit 1
NetworkConnTest
for each_pkg in apache2 redmine mysql-server
do  python lib/checkInstall.py $each_pkg --install || exit 1
done
if [ "$#" -ne 0 ]; then
    case $1 in
    -y|--yes)
        [ `echo $2 | grep -cE "^mysql_passwd=\w+$"` -ne 0 ] && MYSQL_PASS=`echo $2 | cut -d\= -f2` || exit 1
        [ `echo $3 | grep -cE "^redmine_passwd=\w+$"` -ne 0 ] && REDMINE_PASS=`echo $3 | cut -d\= -f2` || exit 1
        NOASK=1;;
    esac
fi
if [ $NOASK -eq 0 ]; then
    python lib/notification.py "Setup redmine server will take 5-10 minutes, Are you sure? [y/N]: " "${LINE}\n${PURPLE}Web service apache2 download and setup starting:${NC}\n${LINE}\n" || exit 0
fi
[ -z "$MYSQL_PASS" ] && python lib/user_creator.py "Set MySQL root password:" && MYSQL_PASS=`cat /tmp/account.cache` && rm -f /tmp/account.cache
[ -z "$REDMINE_PASS" ] && python lib/user_creator.py "Set Redmine admin password:" && REDMINE_PASS=`cat /tmp/account.cache` && rm -f /tmp/account.cache
configure_apache2
configure_mysql
service apache2 restart
update-rc.d apache2 enable
printf "${LINE}\n\n${PURPLE}Redmine Server Info:${NC}\n * Server site - ${GREEN}${PROTOCOL}://`python lib/gethostIPaddr.py`${NC}${RED}:${PORT}${NC}\n * Admin User - ${GREEN}admin${NC}\n * Password - ${GREEN}admin${NC}\n\n"
