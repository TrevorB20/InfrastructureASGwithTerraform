terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Creating Launch Template
resource "aws_launch_template" "Apache1" {
  name          = "Apache1"
  image_id      = "ami-085ad6ae776d8f09c"
  instance_type = "t2.micro"
  user_data     = base64encode(file("Script_apache.sh"))

}
# Auto Scaling Group
resource "aws_autoscaling_group" "ASG1" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  launch_template {
    id      = aws_launch_template.Apache1.id
    version = "$Latest"
  }
}

#Creating Subnets
data "aws_subnets" "mySubnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [var.subnet_id1, var.subnet_id2]
  }
}
#Create Security Group For Server
resource "aws_security_group" "LUITSG" {
  name        = "LUITSG"
  description = "Allow traffic on necessary ports"
  vpc_id      = var.vpc_id

  tags = {
    Name = "LUITSG"
  }

  #Allow Acces on port 8080
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow Traffic on port 80
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow Traffic on port 443
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Allow access on port 22
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/32"] #Get Your Own IP from your Local machine
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating S3 Bucket
terraform {
  backend "s3" {
    bucket = "tb-terraform-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

