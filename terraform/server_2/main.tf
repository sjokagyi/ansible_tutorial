resource "aws_key_pair" "ansible-tutorial" {
  key_name   = "ansible-tutorial"
  public_key = file("~/.ssh/ansible-tutorial.pub")
}

resource "aws_vpc" "ansible-tutorial-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ansible-tutorial-vpc"
  }
}

# 2. Create Internet Gateway(aws_internet_gateway)

resource "aws_internet_gateway" "ansible-tutorial-igw" {
  vpc_id = aws_vpc.ansible-tutorial-vpc.id

  tags = {
    Name = "ansible-tutorial-igw"
  }
}

# 3. Create Custom Route Table(aws_route_table)

resource "aws_route_table" "ansible-tutorial-route-table" {
  vpc_id = aws_vpc.ansible-tutorial-vpc.id

  route {                   # For IPv4 routing
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ansible-tutorial-igw.id
  }

  route {                   # For IPv6 routing
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.ansible-tutorial-igw.id
  }

  tags = {
    Name = "ansible-tutorial-route-table"
  }
}

# 4. Create a Subnet(aws_subnet)

resource "aws_subnet" "ansible-tutorial-subnet-1" {
  vpc_id     = aws_vpc.ansible-tutorial-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "ansible-tutorial-subnet-1",
  }
}

# 5. Associate subnet with Route Table(aws_route_table_association)

resource "aws_route_table_association" "ansible-tutorial-route-table-association" {
  subnet_id      = aws_subnet.ansible-tutorial-subnet-1.id
  route_table_id = aws_route_table.ansible-tutorial-route-table.id
}

# 6. Create Security Group to allow port 22,80,443

resource "aws_security_group" "ansible-tutorial-allow-web-traffic" {
  name        = "ansible-tutorial-allow-web-traffic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.ansible-tutorial-vpc.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port =  443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port =  80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port =  22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port =  0
    protocol =  "-1"             # "-1"  means any protocol.
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-tutorial-allow-web-traffic"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "ansible-tutorial-web-server-nic" {
  subnet_id       = aws_subnet.ansible-tutorial-subnet-1.id
  security_groups = [aws_security_group.ansible-tutorial-allow-web-traffic.id]

  tags = {
    Name = "ansible-tutorial-web-server-nic"
  }

}

# 8. Assign an elastic IP to the network interface created in step 7
#    The deployment of an elastic IP is dependent on the internet gateway so the code should always be below the for the internet gateway
#    It is advisable to set a depends on flag in the aws_eip resource code to indicate that it depends on the internet gateway.
resource "aws_eip" "ansible-tutorial-eip" {
  domain                    = "vpc"
  instance   = aws_instance.ansible-tutorial-web-server-instance.id
  depends_on = [aws_instance.ansible-tutorial-web-server-instance]

  tags = {
    Name = "ansible-tutorial-eip"
  }

}

output "ansible-tutorial-server-public-ip"{
  value  = aws_eip.ansible-tutorial-eip.public_ip
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "ansible-tutorial-web-server-instance"{
    ami = "ami-0ea3c35c5c3284d82"
    instance_type = "t2.micro"
    availability_zone = "us-east-2a" # It is advisable to set the availability zone to prevent AWS from randomly selecting one which can
                                     # cause the availbility zone for the instances element to be mixed with other availability zones.
    key_name = aws_key_pair.ansible-tutorial.id # For using the created key pair.
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.ansible-tutorial-web-server-nic.id
    }

    root_block_device {
      volume_size = 10
    }
    
    user_data = file("userdata.tpl")

    tags = {
        Name = "ansible-tutorial-web-server-instance"
    }

    provisioner "local-exec" {  
      command = templatefile("linux-ssh-config.tpl", { # Ansible works on a Linux Distro so the linux ssh config would be utilized.
        hostname = self.public_ip,
        user = "ubuntu",
        identityfile = "~/.ssh/ansible-tutorial"
      })
      interpreter = ["bash", "-c"]  # For Linux 
    }
}


output "ansible-tutorial-server-private-ip"{
  value  = aws_instance.ansible-tutorial-web-server-instance.private_ip
}

output "ansible-tutorial-server-id"{
  value  = aws_instance.ansible-tutorial-web-server-instance.id
}