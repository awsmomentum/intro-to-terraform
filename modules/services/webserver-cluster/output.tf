output "clb_dns_name" {
  value       = aws_elb.elb-awsmomentum.dns_name
  description = "The domain name of the load balancer"
}

data "aws_availability_zones" "all" {}

output "asg_name" {
  value       = aws_autoscaling_group.autoscalinggrp-momentum.name
  description = "The name of the Auto Scaling Group"
}
