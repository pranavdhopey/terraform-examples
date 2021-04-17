provider "aws" {
  region = var.region
}

resource "aws_instance" "web-server" {
  ami           = lookup(var.ami, var.region)
  instance_type = lookup(var.instance, var.env)
  key_name      = var.ec2_key
  tags          = var.tags
}


resource "aws_eip" "web-ip" {
  instance = aws_instance.web-server.id
  vpc      = true
}