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

  cluster_addons = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
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
          "k8s.io/cluster-autoscaler/enabled"                              = "true"
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

  depends_on = [module.eks]
}