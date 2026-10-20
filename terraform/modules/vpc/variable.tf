variable "cluster_name" {
  type        = string
  description = "Cluster name used for subnet tagging"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs to deploy subnets into"
}