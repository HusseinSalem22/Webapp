provider "aws" {
  region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "app-vpc"
  }
}

# Create a public subnet in AZ eu-west-1a
resource "aws_subnet" "app_subnet_1" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "app-public-subnet-1"
  }
}

# Create a public subnet in AZ eu-west-1b
resource "aws_subnet" "app_subnet_2" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "app-public-subnet-2"
  }
}

# Create private subnets for ECS tasks
resource "aws_subnet" "app_private_subnet_1" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "app-private-subnet-1"
  }
}

resource "aws_subnet" "app_private_subnet_2" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "app-private-subnet-2"
  }
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "app-igw"
  }
}

# Create a NAT Gateway in a public subnet
resource "aws_eip" "app_nat_eip" {
  vpc = true
  tags = {
    Name = "app-nat-eip"
  }
}

resource "aws_nat_gateway" "app_nat_gateway" {
  allocation_id = aws_eip.app_nat_eip.id
  subnet_id     = aws_subnet.app_subnet_1.id
  tags = {
    Name = "app-nat-gateway"
  }
}

# Create a public route table and associate it with public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a private route table and associate it with private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_nat_gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_subnet_1" {
  subnet_id      = aws_subnet.app_private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2" {
  subnet_id      = aws_subnet.app_private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Group for ALB
resource "aws_security_group" "app_lb_sg" {
  name_prefix = "app-lb-sg-"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg-"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"
}


# Create a CloudWatch Log Group for ECS Task
resource "aws_cloudwatch_log_group" "ecs_task_log_group" {
  name              = "/ecs/app-task"
  retention_in_days = 7  # Adjust as needed (e.g., 7 days)
  tags = {
    Name = "ecs-task-log-group"
  }
}


# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([{
    name      = "app-container"
    image     = "husseinsalem799/appen:latest"
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_task_log_group.name
        awslogs-region        = "eu-west-1"
        awslogs-stream-prefix = "app"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.app_private_subnet_1.id, aws_subnet.app_private_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "app-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.app_listener]
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_lb_sg.id]
  subnets            = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]

  tags = {
    Name = "app-lb"
  }
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}
