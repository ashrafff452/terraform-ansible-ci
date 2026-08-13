terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------
# Amazon Linux VM
# ------------------------------------------------

resource "aws_instance" "amazon_linux" {

  ami           = var.ami_amazon_linux
  instance_type = var.instance_type

  key_name = var.key_name

  subnet_id = var.subnet_id

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = {
    Name     = "c8.local"
    Hostname = "c8.local"
    OS       = "Amazon-Linux"
  }
}

# ------------------------------------------------
# Ubuntu 26.04 VM
# ------------------------------------------------

resource "aws_instance" "ubuntu" {

  ami           = var.ami_ubuntu_26
  instance_type = var.instance_type

  key_name = var.key_name

  subnet_id = var.subnet_id

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = {
    Name     = "u26.local"
    Hostname = "u26.local"
    OS       = "Ubuntu-26.04"
  }
}