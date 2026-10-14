#Creating the VPC
resource "aws_vpc" "MyVpc" {
  cidr_block = var.cidr

  tags = {
    Name = "My-VPC"
  }
}

#Creating the Subnets 
resource "aws_subnet" "first-subnet" {
  vpc_id                  = aws_vpc.MyVpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "second-subnet" {
  vpc_id                  = aws_vpc.MyVpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

#Create the IGW
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.MyVpc.id
}

#Creating the Route Table
resource "aws_route_table" "MyRT" {
  vpc_id = aws_vpc.MyVpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

#Associating the Subnets to the Route Table
resource "aws_route_table_association" "subnet-association-1" {
  subnet_id      = aws_subnet.first-subnet.id
  route_table_id = aws_route_table.MyRT.id
}

resource "aws_route_table_association" "subnet-association-2" {
  subnet_id      = aws_subnet.second-subnet.id
  route_table_id = aws_route_table.MyRT.id
}

#Creating the Security Gropus 
resource "aws_security_group" "MySG" {
  name        = "web-sg"
  description = "Inbound rules to allow traffic"
  vpc_id      = aws_vpc.MyVpc.id
  tags = {
    Name = "Inbound Rule"
  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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

#Creating the S3 Bucket
resource "aws_s3_bucket" "MyS3" {
  bucket = "my-first-bucket-dilli-2026"
}

#Creating the Ec2 instances 
resource "aws_instance" "web-server-1" {
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.MySG.id]
  subnet_id              = aws_subnet.first-subnet.id
  user_data_base64       = base64encode(file("userdata.sh"))
  tags = {
    Name = "User-Instance"
  }
}

resource "aws_instance" "web-server-2" {
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.MySG.id]
  subnet_id              = aws_subnet.second-subnet.id
  user_data_base64       = base64encode(file("clientdata.sh"))
  tags = {
    Name = "Client-Instance"
  }
}

#Creating the Load Balancer
resource "aws_lb" "MyLB" {
  name               = "MYALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.MySG.id]
  subnets         = [aws_subnet.first-subnet.id, aws_subnet.second-subnet.id]

  tags = {
    Name = "WEb-ALB"
  }

}

resource "aws_lb_target_group" "MyTG" {
  name     = "MyTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.MyVpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.MyTG.arn
  target_id        = aws_instance.web-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.MyTG.arn
  target_id        = aws_instance.web-server-2.id
  port             = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.MyLB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.MyTG.arn
    type             = "forward"
  }
}