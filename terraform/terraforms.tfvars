aws_region    = "us-east-1"
project_name  = "rag-api"
environment   = "dev"

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

eks_cluster_version     = "1.27"
eks_node_instance_types = ["t3.xlarge"]
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 4

enable_gpu_nodes        = false
gpu_node_instance_types = ["g4dn.xlarge"]
gpu_node_desired_size   = 0

tags = {
  Team = "platform"
}