variable "region" {
  description = "Select the region to setup resources"
  default     = "ap-south-1"
}

variable "env" {
  type = string
}

variable "tags" {
  type = object({
    Name        = string
    Environment = string
  })
}

variable "instance" {
  type = map
  default = {
    dev  = "t2.nano"
    test = "t2.micro"
    prod = "t2.medium"
  }
}

variable "ami" {
  type = map
  default = {
    "ap-south-1"     = "ami-0bcf5425cdc1d8a85"
    "us-east-1"      = "ami-0742b4e673072066f"
    "ap-southeast-1" = "ami-03ca998611da0fe12"
  }
}

variable "ec2_key" {
  description = "Name of the SSH keypair to use in AWS."
  type        = string
}
