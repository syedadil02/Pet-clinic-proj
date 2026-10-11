# ----------------------------------------
# Amazon EKS Cluster
# ----------------------------------------

resource "aws_eks_cluster" "petclinic" {
  name     = "petclinic"
  version  = "1.34"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.petclinic_az1.id,
      aws_subnet.petclinic_az2.id
    ]

    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = {
    Name        = "petclinic-eks"
    Environment = "dev"
    Project     = "PetClinic"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}


# ----------------------------------------
# EKS Managed Node Group
# ----------------------------------------

resource "aws_eks_node_group" "petclinic" {
  cluster_name    = aws_eks_cluster.petclinic.name
  node_group_name = "petclinic-workers"
  node_role_arn   = aws_iam_role.eks_node.arn

  # Workers only in eu-north-1b
  subnet_ids = [
    aws_subnet.petclinic_az2.id
  ]

  instance_types = [
    "m7i-flex.large"
  ]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "petclinic-worker"
    Environment = "dev"
    Project     = "PetClinic"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy,
    aws_iam_role_policy_attachment.eks_node_ecr_policy,
    aws_iam_role_policy_attachment.eks_node_cni_policy
  ]
}
