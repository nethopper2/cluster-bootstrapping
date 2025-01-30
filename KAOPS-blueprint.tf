# This gets the api key from the nethopper secret to be able to interact with the backend
data "kubernetes_resource" "nethopper-config" {
  api_version = "v1"
  kind        = "Secret"

  metadata {
    name      = "nethopper-config"
    namespace = "${var.agent_namespace}"
  }
}
# Creates a clutser in NH, attaches it to the network, and generates install instructions
data "http" "bootstrap-cluster" {
  url = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL)}"
  method = "POST"
  request_headers = {
    apikey = "${base64decode(data.kubernetes_resource.nethopper-config.object.data.API_KEY)}"
    content-type = "application/json"
  }

  request_body = "{\"query\":\"mutation BootstrapCluster($args:CreateClusterInput!){\\ncreateCluster(args:$args){\\nid\\n}\\n}\",\"variables\":{\"args\":{\"name\":\"cloudflow-${var.cluster-name-suffix}\",\"k8sDistro\":\"AKS\",\"systemType\":\"KUBERNETES\",\"clusterRole\":\"EDGE\",\"namespace\":\"default\"}}}"
}

# This goes and gets the generated install instructions via curl
data "curl" "get-nethopper-agent-manifest" {
  http_method = "GET"
  uri = "${replace(base64decode(data.kubernetes_resource.nethopper-config.object.data.API_URL), "graphql", "install")}/${jsondecode(data.http.create-install-object.response_body).data.createInstallObject}"
}

# This saves install instructions to a a docs object to keep in memory
data "kubectl_file_documents" "docs" {
    content = data.curl.get-nethopper-agent-manifest.response
}

# Looping through each resource in the manifest and applying
resource "kubectl_manifest" "nethopper-agent" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}
