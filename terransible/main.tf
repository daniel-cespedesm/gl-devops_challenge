provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#------ VPC ------

resource "aws_vpc" "gorilla_logic_challenge_vpc" {
  cidr_block           = "${var.vpc_cidr}"

  tags {
    Name = "gorilla_logic_challenge_vpc"
  }

}

#internet gateway

resource "aws_internet_gateway" "gorilla_logic_challenge_internet_gateway" {
  vpc_id = "${aws_vpc.gorilla_logic_challenge_vpc.id}"

  tags {
    Name = "gorilla_logic_challenge_igw"
  }
}

#route tables

resource "aws_route_table" "gorilla_logic_challenge_public_rt" {
  vpc_id = "${aws_vpc.gorilla_logic_challenge_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gorilla_logic_challenge_internet_gateway.id}"
  }

  tags {
    Name = "gorilla_logic_challenge_public"
  }
}

/*resource "aws_default_route_table" "jenkins_private_rt" {
  default_route_table_id = "${aws_vpc.gorilla_logic_challenge_vpc.default_route_table_id}"

  tags {
    Name = "jenkins_private"
  }
}*/

# Subnets declaration

resource "aws_subnet" "gorilla_logic_challenge_public1_subnet" {
  vpc_id                  = "${aws_vpc.gorilla_logic_challenge_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "gorilla_logic_challenge_public1"
  }
}

/*resource "aws_subnet" "jenkins_private1_subnet" {
  vpc_id                  = "${aws_vpc.gorilla_logic_challenge_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins_private1"
  }
}*/

# Subnet asociations

resource "aws_route_table_association" "gorilla_logic_challenge_public1_assoc" {
  subnet_id      = "${aws_subnet.gorilla_logic_challenge_public1_subnet.id}"
  route_table_id = "${aws_route_table.gorilla_logic_challenge_public_rt.id}"
}

#Public Security Group

resource "aws_security_group" "gorilla_logic_challenge_public_sg" {
  name        = "gorilla_logic_challenge_public_sg"
  description = "Used for public access to jenkins and jenkins"
  vpc_id      = "${aws_vpc.gorilla_logic_challenge_vpc.id}"

  #jenkins

  /*ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  #Hygieia

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Ssh

/*  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*resource "aws_security_group" "jenkins_private_sg" {
  name        = "jenkins_private_sg"
  description = "Used for access to private instances"
  vpc_id      = "${aws_vpc.gorilla_logic_challenge_vpc.id}"

  #All VPC

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/

#------ Golden ami ------

#Key Pair

resource "aws_key_pair" "gorilla_logic_challenge_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#Jenkins ec2

resource "aws_instance" "jenkins_ec2" {
  instance_type = "${var.ec2_instance_type}"
  ami           = "${var.ec2_ami}"
  private_ip = "10.0.0.7"

  tags {
    Name = "jenkins_ec2"
  }

  key_name               = "${aws_key_pair.gorilla_logic_challenge_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.gorilla_logic_challenge_public_sg.id}"]
  subnet_id              = "${aws_subnet.gorilla_logic_challenge_public1_subnet.id}"

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[jenkins]
${aws_instance.jenkins_ec2.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.jenkins_ec2.id} --profile ${var.aws_profile} && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i aws_hosts jenkins.yml"
  }
}

#Hygieia ec2

resource "aws_instance" "hygieia_ec2" {
  instance_type = "${var.ec2_instance_type_hygieia}"
  ami           = "${var.ec2_ami}"
  private_ip = "10.0.0.14"

  root_block_device {
        volume_size = 20
    }

  tags {
    Name = "hygieia_ec2"
  }

  key_name               = "${aws_key_pair.gorilla_logic_challenge_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.gorilla_logic_challenge_public_sg.id}"]
  subnet_id              = "${aws_subnet.gorilla_logic_challenge_public1_subnet.id}"

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
# AWS infrastructure hosts
[hygieia]
${aws_instance.hygieia_ec2.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.hygieia_ec2.id} --profile ${var.aws_profile} && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i aws_hosts -e 'jenkins_master=10.0.0.7' hygieia.yml"
  }
}
