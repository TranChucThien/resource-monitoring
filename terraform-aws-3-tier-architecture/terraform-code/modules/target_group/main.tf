
resource "aws_lb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled = true
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = var.target_group_name
  }
}

# resource "aws_lb_target_group_attachment" "this" {
#   for_each         = toset(var.instance_ids)
#   target_group_arn = aws_lb_target_group.this.arn
#   target_id        = each.value
#   port             = var.target_group_port
# }

resource "aws_lb_target_group_attachment" "this" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.instance_ids[count.index]
  port             = var.target_group_port
}

