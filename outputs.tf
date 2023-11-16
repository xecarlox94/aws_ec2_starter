
output "instance_id" {
    description = "EC2 instance"
    value       = aws_instance.app_server.id
}

output "public_ip" {
    description = "EC2 public IP"
    value       = aws_instance.app_server.public_ip
}


output "domain-name" {
  value = aws_instance.app_server.public_dns
}

output "application-url" {
  value = "http://${aws_instance.app_server.public_dns}/index.html"
}
