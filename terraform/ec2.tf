resource "aws_key_pair" "ansible" {
  key_name   = "ansible-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible-sg"
  description = "Security group for Ansible practice"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-sg"
  }
}

resource "aws_instance" "servers" {
  for_each = var.servers

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  key_name               = aws_key_pair.ansible.key_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]

  tags = {
    Name = each.key
    Environment = each.key
  }
}