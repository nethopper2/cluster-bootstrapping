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