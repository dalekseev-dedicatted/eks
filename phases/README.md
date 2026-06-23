Two-phase Terraform workflow
===========================

This example shows a safe two-phase approach for creating an EKS cluster and then enabling node pools + Karpenter.

Phase 1 — create cluster + networking only

- Use `examples/phase1.tfvars` which keeps `eks_managed_node_groups = {}` and `create_karpenter = false`.

Commands:

```bash
terraform init -reconfigure
terraform plan -var-file=examples/phase1.tfvars -out=tfplan
terraform apply tfplan
```

Wait for the cluster to be active (or run `terraform output` / check AWS console).

Phase 2 — add node groups and install Karpenter

- Edit `examples/phase2.tfvars` if you want different instance types or sizes, then run:

```bash
terraform plan -var-file=examples/phase2.tfvars -out=tfplan
terraform apply tfplan
```

Notes
- The `create_karpenter` variable controls whether Karpenter-related resources are created.
- The `eks_managed_node_groups` variable should be populated in phase 2 to create managed node groups.
- Keep your AWS credentials available when running `terraform init/plan/apply`.
