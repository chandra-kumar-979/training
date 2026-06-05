module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  # =============================================
  # FIX: Remove aws-ebs-csi-driver from here
  # It is added SEPARATELY below after OIDC is created
  # =============================================
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = merge(
    {
      general = {
        name           = "${var.project_name}-general"
        instance_types = var.eks_node_instance_types
        capacity_type  = var.environment == "dev" ? "SPOT" : "ON_DEMAND"
        min_size       = var.eks_node_min_size
        max_size       = var.eks_node_max_size
        desired_size   = var.eks_node_desired_size
        disk_size      = 50

        labels = {
          role        = "general"
          environment = var.environment
        }

        tags = {
          "k8s.io/cluster-autoscaler/enabled"                                = "true"
          "k8s.io/cluster-autoscaler/${var.project_name}-${var.environment}" = "owned"
        }
      }
    },
      var.enable_gpu_nodes ? {
      gpu = {
        name           = "${var.project_name}-gpu"
        instance_types = var.gpu_node_instance_types
        capacity_type  = "ON_DEMAND"
        min_size       = 0
        max_size       = 2
        desired_size   = var.gpu_node_desired_size
        disk_size      = 100
        ami_type       = "AL2_x86_64_GPU"

        labels = {
          role             = "gpu"
          "nvidia.com/gpu" = "true"
          environment      = var.environment
        }

        taints = [{
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }]
      }
    } : {}
  )
}

# =============================================
# FIX: Add EBS CSI Driver SEPARATELY
# after OIDC provider is created
# =============================================
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    module.eks,
    aws_iam_role.ebs_csi_driver,
    aws_iam_openid_connect_provider.eks
  ]
}

# Get latest EBS CSI driver version
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

# GP3 Storage Class
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    fsType    = "ext4"
    encrypted = "true"
  }

  depends_on = [
    module.eks,
    aws_eks_addon.ebs_csi_driver
  ]
}