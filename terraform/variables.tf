variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region for deployment"
}

variable "cluster_name" {
  type        = string
  default     = "production-eks-cluster"
  description = "Name of the EKS cluster"
}

variable "ecr_repository_name" {
  type        = string
  default     = "cloud-native-api"
  description = "Name of the AWS ECR repository"
}