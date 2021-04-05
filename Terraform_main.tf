#region
provider "aws" {
  region = "ap-south-1"
 access_key = "my-access-key"
  secret_key = "my-secret-key"
}
#myVpc  
resource "aws_vpc" "newVpc" {
  cidr_block       = "10.0.0.0/16"
  
  tags = {
    Name = "newVpc"
  }
}
#myIgw
resource "aws_internet_gateway" "newIgw" {
  vpc_id = aws_vpc.newVpc.id

  tags = {
    Name = "newIgw"
  }
}
#routeTable
resource "aws_route_table" "routeTable" {
  vpc_id = aws_vpc.newVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.newIgw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.newIgw.id
  }

  tags = {
    Name = "routeTable"
  }
}
#mySubnet
resource "aws_subnet" "newSubnet" {
  vpc_id     = aws_vpc.newVpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "newSubnet"
  }
}

#subnetAssociation
resource "aws_route_table_association" "subnetAssociation" {
  subnet_id      = aws_subnet.newSubnet.id
  route_table_id = aws_route_table.routeTable.id
}
#securityGroup
resource "aws_security_group" "newSg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.newVpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "sg-new-vpc"
  }
}
#networkInterface
resource "aws_network_interface" "new-NI" {
  subnet_id       = aws_subnet.newSubnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.newSg.id]
}
#elasticIP
resource "aws_eip" "eip-1" {
  vpc                       = true
  network_interface         = aws_network_interface.new-NI.id
  associate_with_private_ip = "10.0.0.50"
  depends_on = [aws_internet_gateway.newIgw]
}
#ubuntuInstance
resource "aws_instance" "Ubuntu" {
  ami = "ami-0d758c1134823146a"
  instance_type = "t2.micro"
   key_name = "azhar1297"
   tags = {
    Name = "NewUbuntu"
  }
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.new-NI.id
  }
 #userData
   user_data = <<-EOF
             #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo mywebserver > /var/www/html/index.html'
              EOF

}
