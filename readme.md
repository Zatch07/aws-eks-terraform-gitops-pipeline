# End-to-End Cloud-Native GitOps Pipeline on AWS

Production-ready reference architecture demonstrating Infrastructure as Code (IaC) with **Terraform**, multi-stage container builds with **Docker**, automated CI/CD with **GitHub Actions**, and container orchestration on **Amazon EKS** featuring autoscaling and zero-downtime rolling deployments.

---

## Architecture Overview

```text
  Developer Push
        │
        ▼
┌──────────────────┐
│  GitHub Actions│ ──► [Lint & Test] ──► [Trivy Vulnerability Scan]
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│    Amazon ECR  │ ──► Stores immutable versioned images (:git-sha)
└────────┬─────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────────┐
│                 Amazon VPC (Multi-AZ)                       │
│                                                             │
│   ┌───────────────────────────----┐ ┌────────────────────────────┐ │
│   │       Public Subnet        │ │     Private Subnet      │ │
│   │                            │ │                         │ │
│   │   [AWS Ingress / ALB]      │ │    [Amazon EKS Nodes]   │ │
│   │            │               │ │            │            │ │
│   │            ▼               │ │            ▼            │ │
│   │  [NGINX Ingress Controller]│ │  [FastAPI Microservice] │ │
│   │            │               │ │   - Pod AutoScaling     │ │
│   │            └─────────────────┼─┼─► - ClusterIP Service   │ │
│   │                            │ │   - Non-Root Security   │ │
│   └───────────────────────────────┘ └────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘