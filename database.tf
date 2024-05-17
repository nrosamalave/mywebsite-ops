resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/23"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1a", "us-east-1b" # Change to your preferred AZ
}

resource "aws_security_group" "rds_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "rds_security_group"
  description = "Allow access to RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your preferred CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
    cidr_blocks = ["174.179.163.53/32"] # Use your IP range for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet1.id]
}

resource "aws_db_instance" "main" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  db_name                 = "mydatabase"
  manage_master_user_password = true
  username             = "admin"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true

  tags = {
    Name = "terraform-rds"
  }
}
