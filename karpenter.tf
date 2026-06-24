// Deploy Karpenter via Helm. Requires the EKS cluster to exist.

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  token = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes = {
    host = module.eks.cluster_endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "karpenter" {
  count = var.create_karpenter ? 1 : 0
  metadata {
    name = "karpenter"
  }
}

resource "aws_iam_role" "karpenter" {
  count = var.create_karpenter ? 1 : 0
  name = "karpenter-controller-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter" {
  count = var.create_karpenter ? 1 : 0
  name        = var.karpenter_policy_name != "" ? var.karpenter_policy_name : "karpenter-controller-policy-${var.cluster_name}"
  description = "Permissions for Karpenter controller to manage compute resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:Describe*",
          "ec2:AttachVolume",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeImages",
          "ec2:GetSubnetCidrReservations"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_attach" {
  count = var.create_karpenter ? 1 : 0
  role       = aws_iam_role.karpenter[0].name
  policy_arn = aws_iam_policy.karpenter[0].arn
}

resource "kubernetes_service_account" "karpenter" {
  count = var.create_karpenter ? 1 : 0
  metadata {
    name      = "karpenter"
    namespace = kubernetes_namespace.karpenter[0].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter[0].arn
    }
  }
}

resource "helm_release" "karpenter" {
  count = var.create_karpenter ? 1 : 0
  name             = "karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  repository       = "https://charts.karpenter.sh"
  namespace        = kubernetes_namespace.karpenter[0].metadata[0].name
  create_namespace = false

  set = [
    {
      name  = "controller.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "controller.clusterEndpoint"
      value = module.eks.cluster_endpoint
    },
    {
      name  = "controller.clusterResourceNamespace"
      value = "karpenter"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "karpenter"
    }
  ]

  depends_on = [kubernetes_service_account.karpenter, aws_iam_role_policy_attachment.karpenter_attach]
}

# Create Karpenter Provisioners for Spot and On-Demand capacity types.
# Karpenter will only launch nodes when pods request them (so default is 0 nodes).
resource "null_resource" "provisioner_spot" {
  count = var.create_karpenter ? 1 : 0

  triggers = {
    instance_types = join(",", var.node_instance_types)
    chart_version  = var.karpenter_chart_version
  }

  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: provisioner-spot
  namespace: karpenter
spec:
  provider:
    instanceTypes: ${jsonencode(var.node_instance_types)}
    capacityType: "spot"
  requirements:
  - key: kubernetes.io/os
    operator: In
    values: ["linux"]
EOF
EOT
  }

  depends_on = [helm_release.karpenter]
}

resource "null_resource" "provisioner_ondemand" {
  count = var.create_karpenter ? 1 : 0

  triggers = {
    instance_types = join(",", var.node_instance_types)
    chart_version  = var.karpenter_chart_version
  }

  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: provisioner-ondemand
  namespace: karpenter
spec:
  provider:
    instanceTypes: ${jsonencode(var.node_instance_types)}
    capacityType: "on-demand"
  requirements:
  - key: kubernetes.io/os
    operator: In
    values: ["linux"]
EOF
EOT
  }

  depends_on = [helm_release.karpenter]
}
