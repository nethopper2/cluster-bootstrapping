# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes
# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.
provider "aws" {
  region = var.region
  shared_credentials_file = "aws-creds.ini"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}
    
#Modules _must_ use remote state. The provider does not persist state.
terraform {
  backend "kubernetes" {
    secret_suffix     = "providerconfig-default"
    namespace         = "default"
    in_cluster_config = true
  }
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "privateai3-${var.cluster-name-suffix}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}


data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# # Fetch NVIDIA device plugin YAML from GitHub
# data "http" "nvidia_device_plugin" {
#   url = "https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v1.12/nvidia-device-plugin.yml"
# }

# # Apply NVIDIA plugin as a Kubernetes manifest
# resource "kubernetes_manifest" "nvidia_device_plugin" {
#   manifest = yamldecode(data.http.nvidia_device_plugin.body)
# }