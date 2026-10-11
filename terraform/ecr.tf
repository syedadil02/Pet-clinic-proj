resource "aws_ecr_repository" "petclinic" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  force_delete = false
}
