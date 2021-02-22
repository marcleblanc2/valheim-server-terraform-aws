output "ec2-instance-public-ip" {

    value = aws_instance.valheim-server-ec2-instance.public_ip
  
}
output "ec2-instance-public-dns-name" {

    value = aws_instance.valheim-server-ec2-instance.public_dns
  
}
output "ec2-instance-route53-fqdn" {

    value = aws_route53_record.valheim-server-route53-record.fqdn
  
}
