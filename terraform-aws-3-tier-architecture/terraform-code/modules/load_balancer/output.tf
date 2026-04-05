output "load_balancer_arn" {
  value       = aws_lb.this.arn
  description = "The ARN of the load balancer."
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}