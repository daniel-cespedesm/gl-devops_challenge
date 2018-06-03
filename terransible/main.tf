provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#------ VPC ------

resource "aws_vpc" "jenkins_hygieia_env_vpc" {
  cidr_block           = "${var.vpc_cidr}"
/*  enable_dns_hostnames = false
  enable_dns_support   = false*/

  tags {
    Name = "jenkins_hygieia_env_vpc"
  }

}

#internet gateway

resource "aws_internet_gateway" "jenkins_hygieia_env_internet_gateway" {
  vpc_id = "${aws_vpc.jenkins_hygieia_env_vpc.id}"

  tags {
    Name = "jenkins_hygieia_env_igw"
  }
}

#route tables

resource "aws_route_table" "jenkins_hygieia_env_public_rt" {
  vpc_id = "${aws_vpc.jenkins_hygieia_env_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins_hygieia_env_internet_gateway.id}"
  }

  tags {
    Name = "jenkins_hygieia_public"
  }
}

/*resource "aws_default_route_table" "jenkins_hygieia_private_rt" {
  default_route_table_id = "${aws_vpc.jenkins_hygieia_env_vpc.default_route_table_id}"

  tags {
    Name = "jenkins_hygieia_private"
  }
}*/

# Subnets declaration

resource "aws_subnet" "jenkins_hygieia_env_public1_subnet" {
  vpc_id                  = "${aws_vpc.jenkins_hygieia_env_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins_hygieia_public1"
  }
}

/*resource "aws_subnet" "jenkins_hygieia_private1_subnet" {
  vpc_id                  = "${aws_vpc.jenkins_hygieia_env_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins_hygieia_private1"
  }
}*/

# Subnet asociations

resource "aws_route_table_association" "jenkins_hygieia_env_public1_assoc" {
  subnet_id      = "${aws_subnet.jenkins_hygieia_env_public1_subnet.id}"
  route_table_id = "${aws_route_table.jenkins_hygieia_env_public_rt.id}"
}

#Public Security Group

resource "aws_security_group" "jenkins_hygieia_env_public_sg" {
  name        = "jenkins_hygieia_env_public_sg"
  description = "Used for public access to jenkins_hygieia and jenkins_hygieia"
  vpc_id      = "${aws_vpc.jenkins_hygieia_env_vpc.id}"

  #jenkins_hygieia

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

/*resource "aws_security_group" "jenkins_hygieia_private_sg" {
  name        = "jenkins_hygieia_private_sg"
  description = "Used for access to private instances"
  vpc_id      = "${aws_vpc.jenkins_hygieia_env_vpc.id}"

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

resource "aws_key_pair" "jenkins_hygieia_env_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#Jenkins ec2

resource "aws_instance" "jenkins_hygieia_ec2" {
  instance_type = "${var.ec2_instance_type}"
  ami           = "${var.ec2_ami}"

  tags {
    Name = "jenkins_hygieia_ec2"
  }

  key_name               = "${aws_key_pair.jenkins_hygieia_env_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.jenkins_hygieia_env_public_sg.id}"]
  subnet_id              = "${aws_subnet.jenkins_hygieia_env_public1_subnet.id}"

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[jenkins]
${aws_instance.jenkins_hygieia_ec2.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.jenkins_hygieia_ec2.id} --profile ${var.aws_profile} && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i aws_hosts hygieia.yml"
  }
}

#K8s ec2

resource "aws_instance" "k8s_cluster_ec2" {
  instance_type = "${var.ec2_instance_type}"
  ami           = "${var.ec2_ami}"

  tags {
    Name = "k8s_cluster_ec2"
  }

  key_name               = "${aws_key_pair.jenkins_hygieia_env_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.jenkins_hygieia_env_public_sg.id}"]
  subnet_id              = "${aws_subnet.jenkins_hygieia_env_public1_subnet.id}"

  provisioner "local-exec" {
    command = <<EOD
cat <<EOF >> aws_hosts
[jenkins]
${aws_instance.k8s_cluster_ec2.public_ip}
EOF
EOD
  }

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.k8s_cluster_ec2.id} --profile ${var.aws_profile} && export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i aws_hosts hygieia.yml"
  }
}
