checkRootUser() {
  USER_ID=$(id -u)

  if [ "$USER_ID" -ne "0" ]; then
    echo -e "\e[31mYou are suppose to be running this script as sudo or root user\e[0m"
    exit 1
  fi
}


statusCheck() {
  if [ $1 -eq 0 ]; then
    echo -e "\e[32mSUCCESS\e[0m"
  else
    echo -e "\e[31mFAILURE\e[0m"
    echo "Check the error log in ${LOG_FILE}"
    exit 1
  fi
}

LOG_FILE=/tmp/roboshop.ec2InstanceCreate
rm -f $LOG_FILE

ECHO() {
  echo -e "=========================== $1 ===========================\n" >>${LOG_FILE}
  echo "$1"
}

APPLICATION_SETUP() {
  id roboshop &>>${LOG_FILE}
  if [ $? -ne 0 ]; then
    ECHO "Add Application User"
    useradd roboshop &>>${LOG_FILE}
    statusCheck $?
  fi

   ECHO "Download Application Content"
   curl -s -L -o /tmp/${COMPONENT}.zip "https://github.com/roboshop-devops-project/${COMPONENT}/archive/main.zip" &>>${LOG_FILE}
   statusCheck $?

   ECHO "Extract Application Archive"
   cd /home/roboshop &&  rm -rf ${COMPONENT} &>>${LOG_FILE} && unzip /tmp/${COMPONENT}.zip &>>${LOG_FILE} && mv ${COMPONENT}-main ${COMPONENT}
   statusCheck $?
}

SYSTEMD_SETUP() {
  chown roboshop:roboshop /home/roboshop/${COMPONENT} -R

  ECHO "Updated SystemD Configuration Files"
  sed -i -e 's/MONGO_DNSNAME/mongodb.roboshop.internal/' -e 's/REDIS_ENDPOINT/redis.roboshop.internal/' -e 's/MONGO_ENDPOINT/mongodb.roboshop.internal/' -e 's/CATALOGUE_ENDPOINT/catalogue.roboshop.internal/' -e 's/CARTENDPOINT/cart.roboshop.internal/' -e 's/DBHOST/mysql.roboshop.internal/' -e 's/CARTHOST/cart.roboshop.internal/' -e 's/USERHOST/user.roboshop.internal/' -e 's/AMQPHOST/rabbitmq.roboshop.internal/' /home/roboshop/${COMPONENT}/system
  statusCheck $?

  ECHO "Setup SystemD Service"
  mv /home/roboshop/${COMPONENT}/system  /etc/systemd/system/${COMPONENT}.service
  systemctl daemon-reload &>>${LOG_FILE} && systemctl enable ${COMPONENT} &>>${LOG_FILE} && systemctl restart ${COMPONENT} &>>${LOG_FILE}
  statusCheck $?
}

NODEJS() {
  ECHO "Configure NodeJS Yum Repos"
  curl -sL https://rpm.nodesource.com/setup_16.x | bash &>>${LOG_FILE}
  statusCheck $?

  ECHO "Install NodeJS"
  yum install nodejs -y gcc-c++ -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Install NodeJS Modules"
  cd /home/roboshop/${COMPONENT} && npm install &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP

}

JAVA() {
  ECHO "Intsalling Java & Maven"
  yum install maven -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Compile Maven Package"
  cd /home/roboshop/${COMPONENT} && mvn clean package &>>${LOG_FILE} && mv target/${COMPONENT}-1.0.jar ${COMPONENT}.jar &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP

}

PYTHON() {
  ECHO "Installing Python"
  yum install python36 gcc python3-devel -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  ECHO "Install Python Dependencies"
  cd /home/roboshop/${COMPONENT} &&  pip3 install -r requirements.txt &>>${LOG_FILE}
  statusCheck $?

  USER_ID=$(id -u roboshop)
  GROUP_ID=$(id -g roboshop)

  ECHO "Update Roboshop Configuration"
  sed -i -e "/^uid/ c uid = ${USER_ID}" -e "/^gid/ c gid = ${GROUP_ID}" /home/roboshop/${COMPONENT}/${COMPONENT}.ini &>>${LOG_FILE}
  statusCheck $?

  SYSTEMD_SETUP

}

GOLANG() {

  ECHO "Install GoLang"
  yum install golang -y &>>${LOG_FILE}
  statusCheck $?

  APPLICATION_SETUP

  SYSTEMD_SETUP

}