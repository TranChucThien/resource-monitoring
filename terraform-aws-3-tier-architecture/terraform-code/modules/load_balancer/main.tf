

resource "aws_lb" "this" {
  name               = var.load_balancer_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  tags = {
    Name = var.load_balancer_name
  }
}

resource "aws_lb_listener" "this" {
  for_each          = { for tg in var.target_groups : tg.port => tg }
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }
}


