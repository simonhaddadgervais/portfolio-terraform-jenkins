

resource "aws_instance" "jenkins" {
  ami = "ami-06b09bfacae1453cb"

  instance_type = "t2.micro"

  key_name = "jenkins-server"
  tags = {
    Name = "Jenkins"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["89.64.67.87/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["89.64.67.87/32"]
  }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic to any IP
  }
}

