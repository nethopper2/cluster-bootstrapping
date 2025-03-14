data "kubernetes_resource" "nethopper-config" {
  api_version = "v1"
  kind        = "Secret"

  metadata {
    name      = "nethopper-config"
    namespace = "${var.agent_namespace}"
  }
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