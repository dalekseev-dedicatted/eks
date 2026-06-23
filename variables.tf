variable "aws_region" {
  description = "AWS region for resources and backend."
  type        = string
  default     = "eu-central-1"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "tf-vpc"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "tf-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_desired_capacity" {
  type    = number
  default = 2
}

variable "node_max_capacity" {
  type    = number
  default = 2
}

variable "node_min_capacity" {
  type    = number
  default = 1
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
  default     = "my-app-repo"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = { Terraform = "true", Environment = "dev" }
}

variable "karpenter_chart_version" {
  description = "(Optional) Karpenter Helm chart version"
  type        = string
  default     = ""
}

variable "create_karpenter" {
  description = "Whether to install Karpenter via Helm (set true after EKS cluster exists)"
  type        = bool
  default     = false
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node groups. Set empty map to skip creation during initial plan."
  type        = map(any)
  default     = {}
}
