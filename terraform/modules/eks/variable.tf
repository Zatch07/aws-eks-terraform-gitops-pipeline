variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.30"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS is deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets for managed node groups"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Worker node instance types"
}