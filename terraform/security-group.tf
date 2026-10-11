resource "aws_security_group" "rds" {
  name        = "petclinic-rds-sg"
  description = "Security group for PetClinic RDS MySQL"
  vpc_id      = aws_vpc.petclinic.id

  ingress {
    description     = "MySQL access from PetClinic EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  ingress {
    description = "MySQL access from PetClinic EKS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    security_groups = [
      aws_eks_cluster.petclinic.vpc_config[0].cluster_security_group_id
    ]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "petclinic-rds-sg"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
