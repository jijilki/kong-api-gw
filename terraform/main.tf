resource "aws_security_group" "kong_sg" {
  name        = "kong-sg"
  description = "Allow kong ports"
  vpc_id      = null // #use default vpc
  ingress {
    description = "Kong proxy (8000)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kong admin (8001)"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


data "aws_ami" "ubuntu" {
  //this is data not a resource
  most_recent = true
  owners = [var.ami_owner] #Canonical
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-${var.ubuntu_version}-amd64-server-*"]
  }
}


resource "aws_instance" "kong" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.kong_sg.id]
  user_data = file("${path.module}/../kong/ec2-userdata.sh")

  tags = {
    Name = "kong-api-gw"
  }
}

