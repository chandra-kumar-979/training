output "ecr_repository_url" {
  value = aws_ecr_repository.rag_api.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}