data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.vpc_name
  cidr    = var.vpc_cidr
  azs     = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnets))
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  tags = var.tags
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name                 = var.ecr_repository_name
  repository_image_scan_on_push   = true
  repository_image_tag_mutability = "IMMUTABLE"
  create_lifecycle_policy        = false
  # Skip creating the ECR repository if it already exists in the account
  create_repository              = false
  tags                            = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.23"


  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # EKS Auto Mode disabled by not providing compute_config
  compute_config = {
    enabled = false
  }

  # Ensure no encryption_config is passed (we disabled KMS creation)
  encryption_config = null

  # Avoid creating a KMS key/alias and CloudWatch log group if they already exist
  create_kms_key                 = false
  create_cloudwatch_log_group    = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags

  depends_on = [module.vpc]
}

# Allow nodes to reach the EKS control plane API (port 443)
resource "aws_security_group_rule" "eks_nodes_to_controlplane" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow nodes to connect to EKS control plane"
}
