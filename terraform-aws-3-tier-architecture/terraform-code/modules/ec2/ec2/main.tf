resource "aws_instance" "my_ec2_instance" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids
  # vpc_security_group_ids = [aws_security_group.this.id] # Uncomment if using a VPC module
  # security_groups = [aws_security_group.my_sg.name]
  user_data = var.user_data
  tags = {
    Name = var.ec2_name
  }


}

