# VPC
resource "aws_vpc" "cloud_web_server" {
  cidr_block = var.cidr_block

  tags = {
    Name = "cloud_web_server"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cloud_web_server.id

  tags = {
    Name = "internet_gateway"
  }
}

# Security group 1, first security group for traffic incoming from the internet
resource "aws_security_group" "security_group_1" {
  name   = var.security_group_prefix[0].name
  vpc_id = aws_vpc.cloud_web_server.id

  ingress {
    description = "everything"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "everything"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group 2, for inbound traffic from security group 1
# For the EC2 instances/auto-scaling group
resource "aws_security_group" "security_group_2" {
  name   = var.security_group_prefix[1].name
  vpc_id = aws_vpc.cloud_web_server.id

  ingress {
    description = "Ruby on Rails"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.security_group_prefix[0].cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.security_group_prefix[0].cidr_block]
  }

  egress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.security_group_prefix[2].cidr_block]
  }
}

# Security group 3, subnet for inbound database requests from the EC2 instances
resource "aws_security_group" "security_group_3" {
  name   = var.security_group_prefix[2].name
  vpc_id = aws_vpc.cloud_web_server.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.security_group_prefix[1].cidr_block]
  }

  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Public Subnet 1 for ALB and NAT gateway 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.cloud_web_server.id
  cidr_block              = var.public_subnet_prefix[0].cidr_block
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true # Launches subnet as public

  tags = {
    Name = var.public_subnet_prefix[0].name
  }
}

# Public Subnet 2 for ALB and NAT gateway 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.cloud_web_server.id
  cidr_block              = var.public_subnet_prefix[1].cidr_block
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true # Launches subnet as public 

  tags = {
    Name = var.public_subnet_prefix[1].name
  }
}

# Subnet for EC2 instances and auto-scaling group
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.cloud_web_server.id
  cidr_block        = var.private_subnet_prefix[0].cidr_block
  availability_zone = var.availability_zones[0]

  tags = {
    Name = var.private_subnet_prefix[0].name
  }
}

# Subnet for EC2 instances and auto-scaling group
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.cloud_web_server.id
  cidr_block        = var.private_subnet_prefix[1].cidr_block
  availability_zone = var.availability_zones[1]

  tags = {
    Name = var.private_subnet_prefix[1].name
  }
}

# Subnet for primary Amazon RDS database
resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.cloud_web_server.id
  cidr_block        = var.private_subnet_prefix[2].cidr_block
  availability_zone = var.availability_zones[0]

  tags = {
    Name = var.private_subnet_prefix[2].name
  }
}

# Subnet for secondary Amazon RDS database
resource "aws_subnet" "private_subnet_4" {
  vpc_id            = aws_vpc.cloud_web_server.id
  cidr_block        = var.private_subnet_prefix[3].cidr_block
  availability_zone = var.availability_zones[1]

  tags = {
    Name = var.private_subnet_prefix[3].name
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false # Makes the load balancer internet facing and not private.
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.security_group_1.id]
  ip_address_type    = "ipv4"

  access_logs {
    enabled = true
    bucket  = data.aws_s3_bucket.alb_logs.id
    prefix  = "access-logs"
  }

  connection_logs {
    enabled = true
    bucket  = data.aws_s3_bucket.alb_logs.id
    prefix  = "connection-logs"
  }
}

# Directs incoming traffic on port 80 to the load balancer's target group
resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# Target group completes health check
resource "aws_lb_target_group" "alb_target_group" {
  name        = "alb-target-group"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.cloud_web_server.id

  health_check {
    path                = "/up" # Path for the health check endpoint
    protocol            = "HTTP"
    port                = 3000
    interval            = 30  # Health check interval in seconds
    timeout             = 10   # Timeout in seconds before considering the health check as failed
    healthy_threshold   = 2   # Number of consecutive successful health checks required to mark the target as healthy
    unhealthy_threshold = 2   # Number of consecutive failed health checks required to mark the target as unhealthy
    matcher             = "200-399" # HTTP codes to consider as healthy responses
  }
}

# Directs incoming traffic from the listener to the instance
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.web_server_1.id
  port             = 3000
}

# Route table for public subnet 1 and public subnet 2
resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.cloud_web_server.id

  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table_1"
  }
}

resource "aws_route_table_association" "assoc_pubsub_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_route_table_association" "assoc_pubsub_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_nat_gateway" "ngw_1" {
  allocation_id = aws_eip.ngw_1_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "ngw_1"
  }
}

resource "aws_nat_gateway" "ngw_2" {
  allocation_id = aws_eip.ngw_2_eip.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "ngw_2"
  }
}

resource "aws_eip" "ngw_1_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "ngw_2_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# Route table for private subnet 1 and private subnet 3
resource "aws_route_table" "route_table_2" {
  vpc_id = aws_vpc.cloud_web_server.id

  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_1.id
  }

  tags = {
    Name = "route_table_2"
  }
}

# Route table for private subnet 2 and private subnet 4
resource "aws_route_table" "route_table_3" {
  vpc_id = aws_vpc.cloud_web_server.id

  route {
    cidr_block = var.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_2.id
  }

  tags = {
    Name = "route_table_3"
  }
}

# Connected to NGW1
resource "aws_route_table_association" "assoc_privsub_1" {
  subnet_id      = aws_subnet.private_subnet_1.id 
  route_table_id = aws_route_table.route_table_2.id
}

# Connected to NGW2
resource "aws_route_table_association" "assoc_privsub_2" {
  subnet_id      = aws_subnet.private_subnet_2.id 
  route_table_id = aws_route_table.route_table_3.id
}

# Connected to NGW1
resource "aws_route_table_association" "assoc_privsub_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.route_table_2.id
}

# Connected to NGW2
resource "aws_route_table_association" "assoc_privsub_4" {
  subnet_id      = aws_subnet.private_subnet_4.id
  route_table_id = aws_route_table.route_table_3.id
}

resource "aws_key_pair" "main_key" {
  key_name   = "main_key"
  public_key = file("~/.ssh/main_key.pub")
}

resource "aws_instance" "web_server_1" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.main_key.id
  vpc_security_group_ids = [aws_security_group.security_group_2.id] 
  subnet_id              = aws_subnet.private_subnet_1.id           
  user_data              = file("ubuntuscript.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "main_instance"
  }
}

resource "aws_instance" "test_instance" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.main_key.id
  vpc_security_group_ids = [aws_security_group.security_group_1.id] # connects EC2 to SG
  subnet_id              = aws_subnet.public_subnet_1.id            # connects EC2 to subnet
  user_data              = file("ubuntuscript.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "test_instance"
  }
}