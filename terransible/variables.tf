variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}

variable "ec2_instance_type" {}
variable "ec2_instance_type_hygieia" {}
variable "ec2_ami" {}
variable "public_key_path" {}
variable "key_name" {}
