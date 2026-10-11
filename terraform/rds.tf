resource "aws_db_instance" "petclinic" {
  identifier = "petclinic-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = "petclinic"
  username = "petclinic"

  manage_master_user_password = true

  port = 3306

  db_subnet_group_name   = aws_db_subnet_group.petclinic.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name        = "petclinic-mysql"
    Environment = "dev"
    Project     = "PetClinic"
  }
}
