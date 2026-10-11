terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-195874016280"
    key            = "petclinic/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "petclinic-terraform-lock"
  }
}
