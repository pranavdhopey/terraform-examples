output "private_ip" {
  value = aws_instance.web-server.private_ip
}

output "elastic_ip" {
  value = aws_eip.web-ip.public_ip
}