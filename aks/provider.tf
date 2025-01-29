# // Modules _must_ use remote state. The provider does not persist state.
# // NOTE: This is for keeping state in CrossPlane in a K8s cluster.
# terraform {
#   backend "kubernetes" {
#     secret_suffix     = "providerconfig-default"
#     namespace         = "default"
#     in_cluster_config = true
#   }
# }

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.48.0"
    }
    curl = {
      source = "anschoewe/curl"
      version = "1.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.5"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  client_id = var.client_id
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
  client_secret = var.client_secret
}

# Kubernetes provider has to be connected to the HUB cluster throug the in-cluster config
provider "kubernetes" {
  config_path    = "/Users/klitwiniuk/Library/Application Support/Lens/kubeconfigs/aa466282-67f9-4ace-9577-f28c2f50582d"
  config_context = "minikube"
}
# Kubectl provider has to be configured to use the just created AKS cluster
provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
}
