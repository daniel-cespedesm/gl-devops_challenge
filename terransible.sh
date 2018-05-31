#!/bin/bash

## Sets Terraform AWS and Ansible dependencies

UPDATE="yes"
TFURL="https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip"
AUTOYUM="/bin/yum install -y"
TFBINPATH="/bin/terraform"
TERRAFORM="/bin/terraform/terraform"
ECHO="/bin/echo"
GITREPO="git@github.com:daniel-cespedesm/gl-devops_challenge.git"
ROOTPATH="~/$(echo $GITREPO | cut -d'/' -f2 | cut -d'.' -f1)/terransible"

while [ $# -gt 0 ]
do
  case $1 in
    -u|--update) UPDATE=$2;shift;;
    -h|--help) $ECHO >&2 \
      "script usage: $0 [command]
-u | --update :: (YES/NO) :: This script by default will update the OS using the yum repositories unless specified using value 'NO'."
	    exit 10;;
    *) $ECHO >&2 \
	    "\"$1\" flag not recognized
script usage: $0 [command]
-u | --update :: (YES/NO) :: This script by default will update the OS using the yum repositories unless specified using value 'NO'."
	    exit 1;;
  esac
done

UPDATE=$(echo $UPDATE | tr '[:lower:]' '[:upper:]')

if [ ($UPDATE != "YES") &&  ($UPDATE != "NO") ]
then
  $ECHO "$UPDATE value is not valid for flag -u|--update, exiting.";
  exit 2;
fi;

function update_os () {
  if [ $UPDATE == "YES" ]
  then
    /bin/yum clean all -y;
    /bin/yum update -y;
  fi;
}

function install_dependencies () {
  $AUTOYUM python-pip;
  $AUTOYUM unzip;
  $AUTOYUM ansible;
  /bin/pip install awscli --upgrade;
  $AUTOYUM git;
}

function setup_terraform () {
  /bin/curl -O $TFURL
  unzip -d /bin/terraform/ $(echo $TFURL | cut -d'/' -f6)
  $ECHO "export PATH=$PATH:$TFBINPATH" >> ~/.bashrc
  export PATH=$PATH:$TFBINPATH;
  $TERRAFORM --version;
}

function setup_ssh_keys () {}
  /bin/ssh-keygen -f ~/.ssh/fruit -q -N ""
  /bin/chmod 0600 ~/.ssh/fruit*
  eval `ssh-agent -s`
  /bin/ssh-add ~/.ssh/fruit
  /bin/ssh-add -l
  $ECHO "It is strongly recommended that you add the below pub key to your gitgub repository";
  $ECHO "######################## PUB KEY ########################"
  /bin/cat ~/.ssh/fruit.pub
  $ECHO "#########################################################"
  /bin/read -p "Press enter to continue"
}

function setup_terransible (){
  $ECHO "Waiting 10 seconds for ssh_key to replicate"
  /bin/wait 10s;
  /bin/git clone $GITREPO
}

function setup_aws () {
  $ECHO "Get the AWS-CLI credentials ready"
  aws configure --profile gorilla
}

update_os;
install_dependencies;
setup_terraform;
setup_ssh_keys;
setup_terransible;
setup_aws;
exit 0;
