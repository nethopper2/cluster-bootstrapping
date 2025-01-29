variable "client_id" {
  type = string
  description = "Azure client id"
}

variable "client_secret" {
  type = string
  description = "Azure client secret"
}

variable "tenant_id" {
  type = string
  description = "Azure tenant id"
  
}

variable "subscription_id" {
  type = string
  description = "Azure subscription id"
}

variable "region" {
  type = string
  description = "Azure region"
  default = "eastus"
}

variable "cluster-name-suffix" {
  description = "Cluster name suffix"
  type        = string
  default     = "aks"
}

variable "agent_namespace" {
  description = "Namespace where the agent is deployed"
  type        = string
  default     = "nethopper"
}
