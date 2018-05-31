provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#------ VPC ------

resource "aws_vpc" "jenkins-hygieia_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = false
  enable_dns_support   = false

  tags {
    Name = "jenkins-hygieia_vpc"
  }
}

#internet gateway

resource "aws_internet_gateway" "jenkins-hygieia_internet_gateway" {
  vpc_id = "${aws_vpc.jenkins-hygieia_vpc.id}"

  tags {
    Name = "jenkins-hygieia_igw"
  }
}

#route tables

resource "aws_route_table" "jenkins-hygieia_public_rt" {
  vpc_id = "${aws_vpc.jenkins-hygieia_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins-hygieia_internet_gateway.id}"
  }

  tags {
    Name = "jenkins-hygieia_public"
  }
}

resource "aws_default_route_table" "jenkins-hygieia_private_rt" {
  default_route_table_id = "${aws_vpc.jenkins-hygieia_vpc.default_route_table_id}"

  tags {
    Name = "jenkins-hygieia_private"
  }
}

# Subnets declaration

resource "aws_subnet" "jenkins-hygieia_public1_subnet" {
  vpc_id                  = "${aws_vpc.jenkins-hygieia_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins-hygieia_public1"
  }
}

resource "aws_subnet" "jenkins-hygieia_private1_subnet" {
  vpc_id                  = "${aws_vpc.jenkins-hygieia_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins-hygieia_private1"
  }
}

# Subnet asociations

resource "aws_route_table_association" "jenkins-hygieia_public1_assoc" {
  subnet_id      = "${aws_subnet.jenkins-hygieia_public1_subnet.id}"
  route_table_id = "${aws_route_table.jenkins-hygieia_public_rt.id}"
}

#Public Security Group

resource "aws_security_group" "jenkins-hygieia_public_sg" {
  name        = "jenkins-hygieia_public_sg"
  description = "Used for public access to jenkins-hygieia and jenkins-hygieia"
  vpc_id      = "${aws_vpc.jenkins-hygieia_vpc.id}"

  #jenkins-hygieia

  ingress {
    from_port   = 0
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Hygieia

  ingress {
    from_port   = 0
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins-hygieia_private_sg" {
  name        = "jenkins-hygieia_private_sg"
  description = "Used for access to private instances"
  vpc_id      = "${aws_vpc.jenkins-hygieia_vpc.id}"

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
}

#------ Golden ami ------

#Key Pair

resource "aws_key_pair" "jenkins-hygieia_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "jenkins-hygieia_ec2" {
  instance_type = "${var.ec2_instance_type}"
  ami           = "${var.ec2_ami}"

  tags {
    Name = "jenkins-hygieia_ec2"
  }

  key_name               = "${aws_key_pair.jenkins-hygieia_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-hygieia_private_sg.id}"]
  subnet_id              = "${aws_subnet.jenkins-hygieia_public1_subnet.id}"

  provisioner "local-exec" {
    command = "aws ec2 wait-status-ok --instance-ids ${aws_instance.jenkins-hygieia_ec2.id} --profile superhero && ansible-playbook -i ${aws_instance.jenkins-hygieia_ec2.public_ip}, jenkins-hygieia.yml"
  }
}
