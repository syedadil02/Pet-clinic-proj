resource "aws_security_group" "ec2" {
  name        = "petclinic-ec2-sg"
  description = "Security group for PetClinic EC2"
  vpc_id      = aws_vpc.petclinic.id

  ingress {
    description = "SSH access from approved IP range"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "petclinic-ec2-sg"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
