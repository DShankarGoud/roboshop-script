#!/usr/bin/env bash

source components/common.sh
checkRootUser

ECHO "Configure NodeJS Yum Repos"
curl -sL https://rpm.nodesource.com/setup_16.x | bash &>>${LOG_FILE}
statusCheck $?

ECHO "Install NodeJS"
yum install nodejs -y gcc-c++ -y &>>${LOG_FILE}
statusCheck $?


id roboshop &>>${LOG_FILE}
if [ $? -ne 0 ]; then
  ECHO "Add Application User"
  useradd roboshop &>>${LOG_FILE}
  statusCheck $?
fi

