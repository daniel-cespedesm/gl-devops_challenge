# gl-devops_challenge

This repository deppends on 2 additional repositories:
https://github.com/daniel-cespedesm/Hygieia and https://hub.docker.com/r/dacesmo/jenkins/

Before start you should have access to an aws account (charges will apply due to the type of machines selected for deployment, however, they can be changed in the terraform.tfvars file, but then Hygieia application will not even be built)

You also need a user setup with programmatic access in AWS which for this scenario is called "gorilla"

Also you need a github account and if you want to modify the Jenkins build and save it you will need a dockerhub account
## Setup
- Copy the file terransible.sh to your local CentOS server and perform the following commands:
      # Become root
      sudo su -

      # Set the script file permissions
      chmod 700 terransible.sh

      # Run the script
      ./terransible.sh

- After completion of the setup you should have a new folder gl-devops_challenge and a ssh key name fruit under ~/.ssh/ folder
- If you follow all the steps from the script execution then you should be ready to start the deploy now, otherwise, if the script failed or the instructions were not followed you will need to:
  - Update your OS
  - Install the below dependencies:
    - python-pip
    - unzip
    - ansible
    - awscli
    - git
  - Setup terraform
  - Create SSH keys
  - Download this repo complete
  - Set up your AWS account using the aws-cli

## Deploy Hygieia
- Once you are ready to start the deployment go to folder gl-devops_challenge/terransible and perform the following commands as root:

      # Init the SSH Keys
      eval `ssh-agent -s`
      ssh-add ~/.ssh/fruit
      # Init terraform
      terraform init

      # Check terraform files and plan infrastructure
      terraform plan -out gorilla_logic_challenge_plan

      # Apply the infrastructure
      terraform apply gorilla_logic_challenge_plan

    The above commands will execute file gl-devops_challenge/terransible/main.tf which will deploy the required aws infrastructure to get 2 aws_ec2 instances, a free t2.micro to host the Jenkins master server, and a paid t2.small to act as a Jenkins slave which will build, dockerize and deploy the Hygieia application and all of its components found in https://github.com/daniel-cespedesm/Hygieia using the Jenkinsfile_main file found in the forked repository.

## Jenkins Orchestration
- Once the deployment is done you will find an aws_hosts file with the respective public ips for the jenkins and hygieia hosts, jenkins wil be accessible in port 8081 and will use username and password gorilla:GorillaLogic to authenticate.

## Hygieia
- Hygieia will be deployed dockerized and be ready by jenkins, currently only the application deploy will work as functions customizations aren't implemented in Jenkins as pipelines.

  Hygieia is built out of a forked repository in github:
    - original hygieia repo: https://github.com/capitalone/Hygieia
    - forked repository: https://github.com/daniel-cespedesm/Hygieia)

  In the forked repository there is a Jenkinsfile_main acting as the orchestrator to make the build, docker and startup actually happen.

  ## Functionality
    - Due to the lack of knowledge on configuring Hygieia, it is very probable that the application does not work as expected or the components don't get to connect between each other. Last time app went up it failed.
    - Only 2 components are being started as when the rest are removed the application tends to connect api-ui-db successfully. If you wish to make test adding components they are being built, you just have to uncomment the components in the docker-compose.yml file and add additional settings to the docker-compose.override.yml

# Author
This repo is owned by Daniel Céspedes and was created exclusively for a DevOps Challenge for Gorilla Logic . Unless Gorilla Logic has additional privacy policies not documented in this document but found in https://gorillalogic.com/ or any other place, you can do whatever you want with this project as all the components are open-source or free to use.

# Disclaimer
The author is not responsible of any wrongful usage given to this. Other than that please remember Hygieia is a t2.small aws instance and can actually apply charges to your billing.
