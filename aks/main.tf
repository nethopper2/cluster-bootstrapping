resource "azurerm_resource_group" "rg" {
  name     = "rg-cloudflow-${var.cluster-name-suffix}"
  location = var.region
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "cloudflow-${var.cluster-name-suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "cloudflow${var.cluster-name-suffix}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "standard_d3_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Development"
  }
}

module "kaops-bootstrap" {
  source = "https://github.com/nethopper2/cluster-bootstrapping/KAOPS-blueprint"
}
