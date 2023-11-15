
output "instance_id" {
    description = "EC2 instance"
    value       = aws_instance.app_server.id
}

output "instance_public_id" {
    description = "EC2 public IP"
    value       = aws_instance.app_server.public_ip
}


