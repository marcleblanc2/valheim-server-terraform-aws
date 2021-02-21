output "ec2-instance-public-dns-name" {

    value = aws_instance.valheim-server-ec2-instance.public_dns
  
}
output "ec2-instance-public-ip" {

    value = aws_instance.valheim-server-ec2-instance.public_ip
  
}
