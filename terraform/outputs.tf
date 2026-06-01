output "public_ips" {
  value = {
    for name, instance in aws_instance.servers :
    name => instance.public_ip
  }
}

output "private_ips" {
  value = {
    for name, instance in aws_instance.servers :
    name => instance.private_ip
  }
}