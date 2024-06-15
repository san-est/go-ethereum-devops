variable "project_id" {
  description = "GCP project name"
  type = string
  default = "go-ethereum-devops"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "go-eth-cluster"
}

variable "node_pool_name" {
  description = "k8s Node Pool Name"
  type = string
  default = "go-eth-nodepool"
}