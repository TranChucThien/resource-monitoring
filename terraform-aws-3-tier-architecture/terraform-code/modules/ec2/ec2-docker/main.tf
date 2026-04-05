provider "aws" {
  region = var.aws_region
}


resource "aws_instance" "tct_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = var.associate_public_ip_address

  tags = {
    Name        = var.tags["Name"]
    Environment = var.tags["Environment"]
    Project     = var.tags["Project"]
    Owner       = var.tags["Owner"]

  }
  provisioner "remote-exec" {
    inline = var.provisioner_commands
    connection {
      type        = "ssh"
      user        = var.instance_user
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }


}

