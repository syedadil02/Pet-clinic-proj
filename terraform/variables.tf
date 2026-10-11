variable "ecr_repository_name" {
  description = "Amazon ECR repository name"
  type        = string
  default     = "petclinic"
}

variable "ssh_allowed_cidr" {
  description = "Trusted IP range permitted to access EC2 over SSH"
  type        = string
}
