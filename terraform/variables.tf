variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_amazon_linux" {
  description = "Amazon Linux AMI ID"
  type        = string
}

variable "ami_ubuntu_26" {
  description = "Ubuntu 26.04 AMI ID"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "subnet_id" {
  type = string
}