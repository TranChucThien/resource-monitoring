

resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id
  # vpc_id      = aws_vpc.this.id # Uncomment if using a VPC module


  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port = ingress.value["from_port"]
      to_port   = ingress.value["to_port"]
      protocol  = ingress.value["protocol"]
      # cidr_blocks = ingress.value["cidr_blocks"]
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
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


