provider "aws" {
  region = "us-west-2"
}

variable "CIDR" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

resource "aws_key_pair" "example" {
  key_name   = "devOps_keypair_dilli"                     # Replace with your desired key name
  public_key = file("/Users/dilli-22677/.ssh/id_rsa.pub") # Replace with the path to your public key file
}


resource "aws_vpc" "MyVPC" {
  cidr_block = var.CIDR
}

resource "aws_subnet" "MySubnet" {
  vpc_id                  = aws_vpc.MyVPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.MyVPC.id
}

resource "aws_route_table" "MyRouteTable" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIGW.id
  }
}

resource "aws_route_table_association" "MyRouteTableAssociation" {
  subnet_id      = aws_subnet.MySubnet.id
  route_table_id = aws_route_table.MyRouteTable.id
}

resource "aws_security_group" "MySecurityGroup" {
  vpc_id = aws_vpc.MyVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  tags = {
    Name = "MySecurityGroup"
  }
}

resource "aws_instance" "MyInstance" {
  ami                    = "ami-02167eae61967e403" # Replace with a valid AMI ID for your region
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.MySubnet.id
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.MySecurityGroup.id]

  tags = {
    Name = "My-ProvisionerInstance"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"                               # Replace with the appropriate username for your EC2 instance
    private_key = file("/Users/dilli-22677/.ssh/id_rsa") # Replace with the path to your private key
    host        = aws_instance.MyInstance.public_ip
    timeout     = "5m"
  }
  # File provisioner to copy a file from local to the remote EC2 instance   
  provisioner "file" {
    source      = "${path.module}/app.py" # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"   # Replace with the path on the remote instance
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",                  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip python3.14-venv", # Example package installation
      "rm -rf /home/ubuntu/venv",
      "python3 -m venv /home/ubuntu/venv",
      "/home/ubuntu/venv/bin/pip install flask",
      "sudo nohup /home/ubuntu/venv/bin/python /home/ubuntu/app.py > /home/ubuntu/app.log 2>&1 &"
    ]
  }
}