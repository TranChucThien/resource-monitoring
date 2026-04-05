output "instance_id" {
  value       = aws_instance.my_ec2_instance.id
  description = "The ID of the EC2 instance."
}

output "public_ip" {
  value       = aws_instance.my_ec2_instance.public_ip
  description = "The public IP address of the EC2 instance."
}


output "private_ip" {
  value       = aws_instance.my_ec2_instance.private_ip
  description = "The private IP address of the EC2 instance."
  
}
