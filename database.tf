resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/23"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1a" # Change to your preferred AZ
}

data "aws_ip_ranges" "cloudfront" {
  services = ["CLOUDFRONT"]
}

resource "aws_security_group" "allow_cloudfront_and_my_ip" {
  name        = "allow_cloudfront_and_my_ip"
  description = "Security group to allow access from CloudFront and my IP only"

  dynamic "ingress" {
    for_each = data.aws_ip_ranges.cloudfront.cidr_blocks
    content {
      description = "Allow CloudFront IP range"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Ingress rule to allow access from your own IP
  ingress {
    description      = "Allow access from my IP"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["174.179.163.53/32"]  # Replace YOUR_IP_ADDRESS with your actual IP address
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_cloudfront_and_my_ip"
  }
}

output "security_group_id" {
  value = aws_security_group.allow_cloudfront_and_my_ip.id
}

resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "web_security_group"
  description = "Allow web traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Use your IP range for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
