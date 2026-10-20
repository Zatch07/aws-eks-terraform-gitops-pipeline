output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS Cluster Name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Kubernetes API server endpoint"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL of the Amazon ECR repository"
}