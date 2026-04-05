output "environment" {
  description = "Current deployment environment"
  value       = var.environment
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.load_balancer.alb_dns_name
}

output "app_url" {
  description = "Application URL"
  value       = "http://${module.load_balancer.alb_dns_name}"
}

output "ec2_bastion_host_public_ip" {
  description = "The public IP address of the Bastion Host"
  value       = module.ec2_bastion_host.public_ip
}
