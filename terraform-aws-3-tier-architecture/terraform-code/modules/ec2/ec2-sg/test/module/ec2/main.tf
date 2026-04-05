# provider "aws" {
#   region = var.aws_region
# }

resource "aws_instance" "my_ec2_instance" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  # count = var.number_instances # Uncomment if using count

  # vpc_security_group_ids = var.security_group_ids
  vpc_security_group_ids = [aws_security_group.this.id] # Uncomment if using a VPC module
  # security_groups = [aws_security_group.my_sg.name]

  tags = {
    Name = var.ec2_name
  }

  provisioner "remote-exec" {
    connection {
      type        = var.connection_type # type = "ssh" # Uncomment if using SSH connection
      user        = var.user            # 
      private_key = file(var.key_path)
      host        = self.public_ip

    }
    inline = var.provisioner_commands # Use the variable for commands]

  }
}

resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id
  # vpc_id      = aws_vpc.this.id # Uncomment if using a VPC module


  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value["from_port"]
      to_port     = egress.value["to_port"]
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"]
    }

  }
}
