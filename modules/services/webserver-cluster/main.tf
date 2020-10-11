

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configuring S3 bucket to save terraform state file
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-awsmomentum"
    key            = "workspaces-example/terraform.tfstate"
    region         = "us-east-1"
    #DynamoDB table to share the state!
    dynamodb_table = "terraform_locks"
    encrypt        = true
  }
  
  }

resource "aws_security_group" "securitygrp" {
  name = "${var.cluster_name}-elb"
  #allow inbound connection
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ELB.
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 }


resource "aws_elb" "elb-awsmomentum" {
  name               = "elb-awsmomentum"
  security_groups    = [aws_security_group.elb.id]
  availability_zones = data.aws_availability_zones.all.names
 
 health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 10
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # This adds a listener for incoming HTTP requests.

  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.elb_port
    instance_protocol = "http"
  }
}

resource "aws_autoscaling_group" "autoscalinggrp-momentum" {
  name                 = "autoscalinggrp-momentum"
  launch_configuration = aws_launch_configuration.launch_config_momentum.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size             = var.min_size
  max_size             = var.max_size
  load_balancers = [aws_elb.elb-awsmomentum.name]
  
  health_check_type = "ELB-awsmomentum"
  tag {
    key                 = "Name"
    value               = "awsmomentum-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "launch_config_momentum" {
  image_id        = var.image_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.securitygrp.id]
  
  user_data = <<-EOF
              #!/bin/bash
			  sudo su
			  yum update -y
			  yum install httpd -y
			  service httpd start
              chkconfig httpd on 
              echo "<html><h1>Good Morning.. Welcome to Terraform World </h1></html>" > /var/www/html/index.html &
              EOF
 
  lifecycle {
    create_before_destroy = true
  }
  
 }