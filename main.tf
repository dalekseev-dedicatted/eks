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
  tags                            = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"


  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Do not pass account_id/partition; create node groups separately if needed

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags

  depends_on = [module.vpc]
}
