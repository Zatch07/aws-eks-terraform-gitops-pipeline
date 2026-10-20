# End-to-End Cloud-Native GitOps Pipeline on AWS EKS

A battle-tested production reference architecture demonstrating **Infrastructure as Code (Terraform)**, **Docker containerization**, automated **CI/CD via GitHub Actions**, and orchestration on **Amazon EKS** with **Prometheus & Grafana** observability.

---

## What the Deployed Architecture Looks Like

```text
                                  INTERNET
                                     │
                                     ▼
                     ┌───────────────────────────────┐
                     │    AWS Application Load       │
                     │          Balancer             │
                     └───────────────┬───────────────┘
                                     │
 ┌───────────────────────────────────┼───────────────────────────────────┐
 │ Amazon VPC (Multi-AZ)             │                                   │
 │                                   ▼                                   │
 │  ┌─────────────────────────────────────────────────────────────────┐  │
 │  │ Public Subnet (NAT Gateway + Ingress Controller)                │  │
 │  │                                                                 │  │
 │  │  ┌─────────────────────────┐                                    │  │
 │  │  │ NGINX Ingress Pods      │                                    │  │
 │  │  └────────────┬────────────┘                                    │  │
 │  └───────────────┼─────────────────────────────────────────────────┘  │
 │                  │ (Routes Internal Traffic)                          │
 │  ┌───────────────┼─────────────────────────────────────────────────┐  │
 │  │ Private Subnet│ (EKS Managed Nodes - No Direct Public IPs)      │  │
 │  │               ▼                                                 │  │
 │  │  ┌─────────────────────────┐       ┌─────────────────────────┐  │  │
 │  │  │ FastAPI App Pods (x2-10)│◄──────┤ Metrics Server / HPA    │  │  │
 │  │  │ - Non-root container    │       └─────────────────────────┘  │  │
 │  │  │ - Health & Ready probes │                                    │  │
 │  │  └────────────▲────────────┘                                    │  │
 │  │               │ Scrapes Metrics (/metrics)                      │  │
 │  │  ┌────────────┴────────────┐       ┌─────────────────────────┐  │  │
 │  │  │ Prometheus Operator     ├──────►│ Grafana Dashboards      │  │  │
 │  │  └─────────────────────────┘       └─────────────────────────┘  │  │
 │  └─────────────────────────────────────────────────────────────────┘  │
 └───────────────────────────────────────────────────────────────────────┘


 Step-by-Step Setup Guide
1. Prerequisites Checklist
Ensure the following tools are installed on your workstation:

AWS CLI v2 configured with administrative credentials (aws configure)

Terraform (>= 1.5.0)

kubectl (>= 1.28)

Helm v3 (>= 3.12)

Docker Engine

2. Provision AWS Infrastructure (Terraform)
Initialize and provision the Multi-AZ VPC, EKS Cluster, Node Groups, and ECR repository:

cd terraform

# 1. Create your tfvars configuration
cp terraform.tfvars.example terraform.tfvars

# 2. Initialize provider plugins and backend
terraform init

# 3. Preview resource changes
terraform plan

# 4. Provision infrastructure (~12-15 minutes)
terraform apply --auto-approve


Save the output values displayed in your terminal (specifically ecr_repository_url and cluster_name).

3. Connect to the EKS Cluster
Update your local kubeconfig to direct kubectl traffic to your new AWS EKS cluster:

aws eks update-kubeconfig --region ap-south-1 --name production-eks-cluster

# Verify nodes are running and ready
kubectl get nodes -o wide

4. Install Cluster Add-Ons
Before running the application, install the standard Kubernetes cluster add-ons:

A. Kubernetes Metrics Server (Required for HPA)

kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# Verify metrics-server pod is running
kubectl get pods -n kube-system -l k8s-app=metrics-server

B. NGINX Ingress Controller

helm repo add ingress-nginx [https://kubernetes.github.io/ingress-nginx](https://kubernetes.github.io/ingress-nginx)
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

5. Install Prometheus & Grafana Stack
Deploy the industry-standard kube-prometheus-stack using Helm and our custom values:

# Add Prometheus community Helm chart repository
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

# Install Prometheus, Alertmanager, and Grafana in the 'monitoring' namespace
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/observability/prometheus-grafana-values.yaml

Verify that the monitoring pods are ready:

kubectl get pods -n monitoring

6. Deploy the Microservice
Option A: Automated via GitHub Actions (Recommended)
Add the following secrets to your GitHub repository under Settings > Secrets and variables > Actions:

Secret Name,               Description / Sample Value
AWS_ACCESS_KEY_ID,         IAM User Access Key
AWS_SECRET_ACCESS_KEY,     IAM User Secret Key
AWS_REGION,                AWS Region (ap-south-1)
ECR_REPOSITORY,            cloud-native-api
EKS_CLUSTER_NAME,          production-eks-cluster

Push any commit to main — the pipeline will automatically lint, build, scan with Trivy, push to ECR, and execute a zero-downtime rollout.