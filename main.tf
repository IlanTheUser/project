# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

################################ VPC ################################
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "172.10.0.0/16"
  
  tags = {
    Name = "Main VPC"
  }
}

################################ internet gateway ################################
# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

################################ subnets ################################
# Create Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.10.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.10.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet 2"
  }
}

# Create Private Subnets
resource "aws_subnet" "private_10" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.10.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet 10"
  }
}

resource "aws_subnet" "private_20" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.10.20.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private Subnet 20"
  }
}

################################ security groups ################################
# Create Security Group for Public Subnets
resource "aws_security_group" "public" {
  name        = "Public Subnet SG"
  description = "Security group for public subnets"
  vpc_id      = aws_vpc.main.id

# Allow inbound HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound SSH (replace x.x.x.x/32 with your IP address)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP (ping) from anywhere"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow this port for flask app"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public SG"
  }
}

# Create Security Group for Private Subnets
resource "aws_security_group" "private" {
  name        = "Private Subnet SG"
  description = "Security group for private subnets"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from public security group
  # ingress {
  #   from_port                = 0
  #   to_port                  = 65535
  #   protocol                 = "tcp"
  #   security_groups          = [aws_security_group.public.id]
  # }

  # Allow inbound SSH (replace x.x.x.x/32 with your IP address)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public.id]
    description     = "Allow SSH from public subnet"
  }

  # ingress {
  #   from_port       = 3306
  #   to_port         = 3306
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.public.id]
  #   description     = "Allow MySQL/MariaDB from web server"
  # }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private SG"
  }
}

################################ route tables ################################
# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Private Route Table"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_10" {
  subnet_id      = aws_subnet.private_10.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_20" {
  subnet_id      = aws_subnet.private_20.id
  route_table_id = aws_route_table.private.id
}