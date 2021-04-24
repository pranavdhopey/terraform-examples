data "aws_ami" "linux2_ami" {
  most_recent = true
  owners      = ["self", "amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "ec2_key" {
  description = "Name of the SSH keypair to use in AWS."
  type        = string
}

variable "security_group" {
  type = list(any)
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
