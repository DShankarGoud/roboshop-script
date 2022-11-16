#!/usr/bin/env bash

source components/common.sh
checkRootUser

ECHO "Configure NodeJS Yum Repos"
curl -sL https://rpm.nodesource.com/setup_16.x | bash &>>${LOG_FILE}
statusCheck $?

