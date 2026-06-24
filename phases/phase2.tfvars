# Phase 2: add managed node groups and install Karpenter
# Example usage:
# terraform plan -var-file=phases/phase2.tfvars -out=tfplan

eks_managed_node_groups = {
  default = {
    desired_size   = 2
    min_size       = 1
    max_size       = 2
    instance_types = ["t3.medium"]
  }
}

create_karpenter = true
karpenter_chart_version = "0.16.3"
karpenter_policy_name = "karpenter-controller-policy-tf-eks-cluster-2"
