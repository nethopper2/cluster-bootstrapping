data "kubernetes_resource" "nethopper-config" {
  api_version = "v1"
  kind        = "Secret"

  metadata {
    name      = "nethopper-config"
    namespace = "${var.agent_namespace}"
  }
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