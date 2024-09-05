provider "aws" {
  region = "us-east-1"
  access_key  = var.aws_access_key
  secret_key  = var.aws_secret_key
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-gateway"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-public-subnet"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

# Launch EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0182f373e66f89c85"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.allow_http.name]
  key_name      = "nv"  # Your key pair name

  tags = {
    Name = "NodeAppServer"
  }

  # User data to install Node.js and start the application
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git curl
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install 20
    nvm use 20  
    git clone https://github.com/SuryaHR/next-app.git
    cd next-app
    npm install
    npm run build
    npm start
  EOF
}
