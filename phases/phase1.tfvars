# Phase 1: create cluster and networking only
# - No managed node groups
# - Do not install Karpenter

eks_managed_node_groups = {}
create_karpenter = false
