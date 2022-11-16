#!/usr/bin/env bash

source components/common.sh
checkRootUser

# curl -s -L -o /etc/yum.repos.d/mysql.repo https://raw.githubusercontent.com/roboshop-devops-project/mysql/main/mysql.repo
# yum install mysql-community-server -y
# systemctl enable mysqld
# systemctl start mysqld
# grep temp /var/log/mysqld.log
# mysql_secure_installation
# mysql -uroot -pRoboShop@1
> uninstall plugin validate_password;
# curl -s -L -o /tmp/mysql.zip "https://github.com/roboshop-devops-project/mysql/archive/main.zip"
# cd /tmp
# unzip mysql.zip
# cd mysql-main
# mysql -u root -pRoboShop@1 <shipping.sql

ECHO "Setup MySQL Yum Repo "
curl -s -L -o /etc/yum.repos.d/mysql.repo https://raw.githubusercontent.com/roboshop-devops-project/mysql/main/mysql.repo &>>${LOG_FILE}
statusCheck $?

ECHO "Install MySQL Server"
yum install mysql-community-server -y &>>${LOG_FILE}
statusCheck $?

ECHO "Start MySQL Service"
systemctl enable mysqld &>>${LOG_FILE} && systemctl start mysqld &>>${LOG_FILE}
statusCheck $?

DEFAULT_PASSWORD=$(sudo grep 'A temporary password' /var/log/mysqld.log | awk '{print $NF}')

echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';" >/tmp/root-pass.sql
mysql --connect-expired-password -u root -p${DEFAULT_PASSWORD} </tmp/root-pass.sql &>>${LOG_FILE}
