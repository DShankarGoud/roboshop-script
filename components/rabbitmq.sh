#!/usr/bin/env bash

source components/common.sh
checkRootUser

ECHO "Setup Yum Repos"
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | sudo bash &>>${LOG_FILE}
statusCheck $?

ECHO "Install RabbitMQ & Erlang"
yum install https://github.com/rabbitmq/erlang-rpm/releases/download/v23.2.6/erlang-23.2.6-1.el7.x86_64.rpm rabbitmq-server -y &>>${LOG_FILE}
statusCheck $?

ECHO "Start RabbitMQ Service"
systemctl enable rabbitmq-server &>>${LOG_FILE} && systemctl start rabbitmq-server &>>${LOG_FILE}
statusCheck $?

rabbitmqctl list_users | grep roboshop &>>${LOG_FILE}
if [ $? -ne 0 ]; then
  ECHO "Create An Application User"
  rabbitmqctl add_user roboshop roboshop123 &>>${LOG_FILE}
  statusCheck $?
fi

ECHO "Setup Application User Permissions"
rabbitmqctl set_user_tags roboshop administrator &>>${LOG_FILE} && rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>${LOG_FILE}
statusCheck $?
