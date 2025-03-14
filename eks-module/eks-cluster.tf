module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.34.0"

  cluster_name    = local.cluster_name
  cluster_version = var.k8s-version 

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "gpu"]
  }

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  tags = {
    Terraform   = "true"
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64_GPU"  # Amazon Linux 2 GPU AMI
    attach_cluster_primary_security_group = true
    create_security_group = false
  }

  eks_managed_node_groups = {
    gpu_nodes = {
      name = "gpu-node-group"
      instance_types = ["g4dn.2xlarge"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      vpc_security_group_ids = [aws_security_group.eks_nodes.id]

      subnet_ids = [
        module.vpc.private_subnets[0],
        module.vpc.private_subnets[1],
        module.vpc.private_subnets[2]
      ]

      pre_bootstrap_user_data = <<-EOT
      echo 'Initializing GPU nodes'
      EOT
    }
  }
}