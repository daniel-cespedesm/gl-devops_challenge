# Terransible
This is and implementation of terraform running ansible playbooks on the recently deployed aws_instances

## Files hierarchy

- ### main.tf
    contains all the terraform aws Infrastructure as Code
- ### variables.tf
contains the variables initialization
- ### terraform.tfvars
contains the variables definitions
- ### aws_hosts
contains the public ips of the Jenkins and Hygieia instances
- ### jenkins.yml
  contains the playbook to be ran on the Jenkins ec2 instance
- ### hygieia.yml
    contains the playbook to be ran on the Hygieia ec2 instance
- ### jenkins_files/
folder that contains the jenkins defitions for the jenksins node and the jenkins pipeline that the Hygieia-node tells the server to work on.

- ### Jenkins_build
this folder contains the required scripts to customize the jenkins docker image used in this project.
  - build.sh: creates the image and uploads it to dockerhub
  - plugins.txt: contains a list of plugins used by Jenkins in its initial setup
  - Dockerfile: contains the instructions to create the docker image, execute the install plugins script in the docker image and setup admin password as gorilla:GorillaLogic
  - security.groovy: groovy script that sets first admin as gorilla:GorillaLogic
  
