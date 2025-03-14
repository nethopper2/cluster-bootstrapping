variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster-name-suffix" {
  description = "Cluster name suffix"
  type        = string
  default     = "eks"
}

variable "k8s-version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "cidr-block" {
  description = "CIDR Block"
  type = list
  default = ["10.0.0.0/8"]
}