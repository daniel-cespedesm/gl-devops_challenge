# gl-devops_challenge
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
