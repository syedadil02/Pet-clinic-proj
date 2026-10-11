resource "aws_db_subnet_group" "petclinic" {
  name        = "petclinic-rds-subnet-group"
  description = "Subnet group for PetClinic RDS MySQL"

  subnet_ids = [
    aws_subnet.petclinic_az1.id,
    aws_subnet.petclinic_az2.id
  ]

  tags = {
    Name        = "petclinic-rds-subnet-group"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
