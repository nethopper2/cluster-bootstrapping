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


data "kubernetes_resource" "nethopper-config" {
  api_version = "v1"
  kind        = "Secret"

  metadata {
    name      = "nethopper-config"
    namespace = "${var.agent_namespace}"
  }
}

data "http" "create-cluster" {
  url = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL)}"
  method = "POST"
  request_headers = {
    apikey = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_KEY)}"
    content-type = "application/json"
  }

  request_body = "{\"query\":\"mutation CreateCluster($args:CreateClusterInput!){\\ncreateCluster(args:$args){\\nid\\n}\\n}\",\"variables\":{\"args\":{\"name\":\"cloudflow-${var.cluster-name-suffix}\",\"k8sDistro\":\"AKS\",\"systemType\":\"KUBERNETES\",\"clusterRole\":\"EDGE\",\"namespace\":\"default\"}}}"
}

data "http" "attach-cluster-to-network" {
  url = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL)}"
  method = "POST"
  request_headers = {
    apikey = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_KEY)}"
    content-type = "application/json"
  }

  request_body = "{\"query\":\"mutation AttachCluster($args:AttachClusterInput!){\\nattachCluster(args:$args){\\ncluster{\\nid\\n}\\n}\\n}\",\"variables\":{\"args\":{\"clusterId\":\"${jsondecode(data.http.create-cluster.response_body).data.createCluster.id}\",\"networkId\":\"${base64decode(data.kubernetes_resource.nethopper-config.object.data.NETWORK_ID)}\"}}}"
}

data "http" "create-agent" {
  depends_on = [ data.http.attach-cluster-to-network ]

  url = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL)}"
  method = "POST"
  request_headers = {
    apikey = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_KEY)}"
    content-type = "application/json"
  }

  request_body = "{\"query\":\"mutation CreateAgent($args:CreateAgentInput!){\\ncreateAgent(args:$args){\\nid\\n}\\n}\",\"variables\":{\"args\":{\"clusterId\":\"${jsondecode(data.http.create-cluster.response_body).data.createCluster.id}\",\"networkId\":\"${base64decode(data.kubernetes_resource.nethopper-config.object.data.NETWORK_ID)}\"}}}"
}

data "http" "create-install-object" {
  url = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL)}"
  method = "POST"
  request_headers = {
    apikey = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_KEY)}"
    content-type = "application/json"
  }

  request_body = "{\"query\":\"mutation CreateInstallObject($args:CreateAgentInstallObjectInput!){\\ncreateInstallObject(args:$args)\\n}\",\"variables\":{\"args\":{\"agentId\":\"${jsondecode(data.http.create-agent.response_body).data.createAgent.id}\"}}}"
}

data "curl" "get-nethopper-agent-manifest" {
  http_method = "GET"
  uri = "${replace(base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL), "graphql", "install")}/${jsondecode(data.http.create-install-object.response_body).data.createInstallObject}"
}

data "kubectl_file_documents" "docs" {
    content = data.curl.get-nethopper-agent-manifest.response
}

resource "kubectl_manifest" "nethopper-agent" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}
