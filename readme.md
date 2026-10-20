# End-to-End Cloud-Native GitOps Pipeline on AWS EKS

<div align="center">

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-232F3E?style=for-the-badge&logo=amazon-eks&logoColor=white)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Trivy](https://img.shields.io/badge/Security-Trivy-00A4A6?style=for-the-badge&logo=aquasecurity&logoColor=white)](https://trivy.dev/)

<p align="center">
  <strong>A production-ready reference architecture demonstrating Infrastructure as Code (Terraform), hardened Docker containerization, automated CI/CD via GitHub Actions, and orchestration on Amazon EKS with Prometheus & Grafana observability.</strong>
</p>

<p align="center">
  <a href="#-architecture-overview">Architecture</a> •
  <a href="#-key-features">Features</a> •
  <a href="#-repository-structure">Repository Structure</a> •
  <a href="#-prerequisites">Prerequisites</a> •
  <a href="#-step-by-step-setup-guide">Setup Guide</a> •
  <a href="#-observability--monitoring">Observability</a> •
  <a href="#-teardown--cleanup">Teardown</a>
</p>

</div>

---

## 🏛 Architecture Overview

Traffic originates from external clients, terminates at the **AWS Application Load Balancer**, and routes through the **NGINX Ingress Controller** into private Kubernetes worker nodes running the hardened **FastAPI** microservice. Workloads scale dynamically via the **Metrics Server** and **HPA**, while the **Prometheus Operator** and **Grafana** continuously ingest performance telemetry.

```mermaid
flowchart TD
    subgraph Internet[" 🌐 Public Internet "]
        User[("👤 Users / Clients")]
    end

    subgraph AWS[" ☁️ Amazon Web Services (AWS) "]
        ALB["⚡ AWS Application Load Balancer"]
        ECR[("📦 Amazon ECR\n(Private Registry)")]

        subgraph VPC[" 🛡️ Amazon VPC (Multi-AZ) "]
            subgraph PublicSubnets[" 🟢 Public Subnets "]
                NAT["🔄 NAT Gateway"]
                Ingress["🚪 NGINX Ingress Controller"]
            end

            subgraph PrivateSubnets[" 🔒 Private Subnets (EKS Managed Nodes) "]
                subgraph Workloads[" 🚀 Application Workloads "]
                    Service["🔌 ClusterIP Service"]
                    Pod1["📦 FastAPI App (Pod 1)"]
                    Pod2["📦 FastAPI App (Pod 2)"]
                    PodN["📦 FastAPI App (Pod N)"]
                    HPA["⚖️ Horizontal Pod Autoscaler\n(Min: 2 / Max: 10 / Target: 70% CPU)"]
                end

                subgraph Monitoring[" 📊 Observability Stack "]
                    MetricsServer["📈 Metrics Server"]
                    Prometheus["🔥 Prometheus Operator"]
                    Grafana["📊 Grafana Dashboards"]
                end
            end
        end
    end

    subgraph GitHub[" 🐙 GitHub Platform "]
        Repo[("📁 Source Code")]
        Actions["⚙️ GitHub Actions CI/CD\n- Flake8 Linting\n- Trivy Vulnerability Scan\n- Docker Multi-stage Build\n- Rolling Update Deployment"]
    end

    %% CI/CD Flow
    Repo --> Actions
    Actions -.->|1. Push Image| ECR
    Actions -.->|2. Rolling Update| Workloads

    %% Traffic Flow
    User -->|HTTPS/HTTP| ALB
    ALB -->|Forward| Ingress
    Ingress -->|Route| Service
    Service --> Pod1
    Service --> Pod2
    Service --> PodN

    %% Autoscaling & Metrics
    Workloads -.-> MetricsServer
    MetricsServer -.-> HPA
    HPA -.->|Scale Out / In| Workloads

    %% Monitoring Flow
    Prometheus -.->|Scrape /metrics| Workloads
    Grafana -->|Query Datasource| Prometheus
    PrivateSubnets -->|Outbound Updates| NAT
    NAT --> Internet
```

<details>
<summary><strong>🔍 Click to expand ASCII Architecture Diagram</strong></summary>

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
```
</details>

---

## ✨ Key Features

| Capability | Implementation | Description |
| :--- | :--- | :--- |
| **Infrastructure as Code** | **Terraform (v1.5+)** | Fully modularized VPC, EKS Cluster (v1.28), IAM OIDC provider for IRSA, and ECR. |
| **Container Hardening** | **Docker Multi-Stage** | Alpine base image running strictly under non-root permissions (`uid/gid: 10001`). |
| **Security Scanning** | **Aqua Trivy** | Integrated into CI pipeline to block builds containing critical/high CVEs. |
| **GitOps CI/CD** | **GitHub Actions** | Automated testing, linting (`flake8`), containerization, and zero-downtime rolling deploys. |
| **Autoscaling & Resilience** | **HPA + Metrics Server** | Horizontal Pod Autoscaling dynamically scaling replicas between 2 and 10 based on CPU load. |
| **Observability** | **Prometheus & Grafana** | Complete cluster monitoring using `kube-prometheus-stack` with persistent metrics & alerting. |
| **Ingress Management** | **NGINX Ingress** | Load balancer routing external HTTP/S requests directly to private ClusterIP microservices. |

---

## 📁 Repository Structure

```tree
aws-eks-terraform-gitops-pipeline/
├── .github/
│   └── workflows/
│       ├── app-ci-cd.yml              # Build, Trivy scan, ECR push, and EKS rollout
│       └── terraform.yml              # Terraform fmt, init, and validation checks
├── app/
│   ├── Dockerfile                     # Multi-stage hardened non-root container build
│   ├── requirements.txt               # FastAPI, Uvicorn, and dependencies
│   └── src/
│       └── main.py                    # Microservice with /healthz and /readyz endpoints
├── k8s/
│   ├── deployment.yaml                # Rolling-update deployment spec with probes
│   ├── service.yaml                   # ClusterIP service exposing port 80 -> 8000
│   ├── hpa.yaml                       # HorizontalPodAutoscaler spec (2-10 replicas)
│   ├── ingress.yaml                   # NGINX Ingress rules
│   └── observability/
│       └── prometheus-grafana-values.yaml  # Custom values for kube-prometheus-stack
├── terraform/
│   ├── main.tf                        # Root Terraform module
│   ├── variables.tf                   # Input variable definitions
│   ├── outputs.tf                     # Cluster and ECR outputs
│   ├── terraform.tfvars.example       # Example variable overrides
│   └── modules/
│       ├── vpc/                       # Multi-AZ VPC, subnets, NAT Gateway, Route Tables
│       └── eks/                       # EKS Control plane, Managed Node Groups, OIDC
└── readme.md                          # Comprehensive project documentation
```

---

## 📋 Prerequisites

Before proceeding, ensure you have configured the following tools on your local workstation:

| Tool | Minimum Version | Installation & Verification |
| :--- | :--- | :--- |
| **AWS CLI** | `>= 2.12.0` | `aws --version` (Configured via `aws configure`) |
| **Terraform** | `>= 1.5.0` | `terraform -version` |
| **kubectl** | `>= 1.28.0` | `kubectl version --client` |
| **Helm** | `>= 3.12.0` | `helm version` |
| **Docker** | `>= 24.0.0` | `docker --version` |

---

## 🚀 Step-by-Step Setup Guide

### 1. Provision Cloud Infrastructure (Terraform)

Provision the Multi-AZ VPC, EKS Cluster, Managed Node Groups, and Amazon ECR repository:

```bash
# Navigate to the Terraform root directory
cd terraform

# 1. Create your tfvars configuration file
cp terraform.tfvars.example terraform.tfvars

# 2. Initialize provider plugins and backend
terraform init

# 3. Preview resource changes
terraform plan

# 4. Provision infrastructure (~12-15 minutes)
terraform apply --auto-approve
```

> [!NOTE]  
> Terraform will provision an AWS EKS Control Plane along with EC2 worker nodes. Creation typically takes **12 to 15 minutes**.

Capture the output values displayed at completion:
```bash
# Extract generated outputs
terraform output cluster_name
terraform output ecr_repository_url
```

---

### 2. Connect to the EKS Cluster

Generate your cluster's `kubeconfig` authentication context using the AWS CLI:

```bash
# Update local kubeconfig (adjust region and cluster name if modified)
aws eks update-kubeconfig --region ap-south-1 --name production-eks-cluster

# Verify nodes are registered and reporting 'Ready' status
kubectl get nodes -o wide
```

---

### 3. Deploy Cluster Add-Ons

#### A. Kubernetes Metrics Server (Required for HPA)
The Metrics Server collects resource utilization metrics used by the Horizontal Pod Autoscaler:

```bash
# Install the latest official Metrics Server manifest
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify the metrics-server deployment is running
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

#### B. NGINX Ingress Controller
Install NGINX Ingress configured as an AWS LoadBalancer to receive ingress traffic:

```bash
# Add official Ingress NGINX chart repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress in dedicated namespace
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

Verify that the Load Balancer hostname is assigned:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

---

### 4. Deploy Prometheus & Grafana Monitoring

Deploy the industry-standard `kube-prometheus-stack` chart using the tailored values located in `k8s/observability/`:

```bash
# Add Prometheus community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus Operator, Alertmanager, and Grafana
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values ../k8s/observability/prometheus-grafana-values.yaml
```

Verify all monitoring pods enter the `Running` state:
```bash
kubectl get pods -n monitoring
```

---

### 5. Configure Automated CI/CD Pipeline (GitHub Actions)

The repository includes a production-grade CI/CD pipeline (`.github/workflows/app-ci-cd.yml`) that performs static analysis, runs container security vulnerability scans with Trivy, pushes images to Amazon ECR, and executes rolling deployments to EKS.

#### Required GitHub Secrets

Navigate to your GitHub repository: **Settings** > **Secrets and variables** > **Actions** and add the following repository secrets:

| Secret Name | Description | Example / Default Value |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | IAM User Access Key with ECR/EKS permissions | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | IAM User Secret Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | Target AWS Region | `ap-south-1` |
| `ECR_REPOSITORY` | Amazon ECR Repository Name | `cloud-native-api` |
| `EKS_CLUSTER_NAME` | Amazon EKS Cluster Name | `production-eks-cluster` |

#### Trigger Deployment

Any push to the `main` branch modifying `app/**` or `k8s/**` triggers the workflow:

```bash
git add .
git commit -m "feat: trigger automated gitops deployment"
git push origin main
```

---

### 6. Alternative: Manual Local Deployment

If you prefer building and deploying directly from your development workstation:

<details>
<summary><strong>🛠️ Click to expand Manual Deployment steps</strong></summary>

```bash
# 1. Authenticate Docker with Amazon ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(terraform -chdir=terraform output -raw ecr_repository_url)

# 2. Build and Tag Docker Image
IMAGE_URI="$(terraform -chdir=terraform output -raw ecr_repository_url):v1.0.0"
docker build -t $IMAGE_URI ./app

# 3. Push Image to ECR
docker push $IMAGE_URI

# 4. Deploy Kubernetes Manifests
sed -i "s|REPOSITORY_URI:IMAGE_TAG|$IMAGE_URI|g" k8s/deployment.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml

# 5. Monitor Rollout Status
kubectl rollout status deployment/cloud-native-api --timeout=120s
```
</details>

---

## 🔍 Application Verification & Health Checks

### Endpoints Reference

The FastAPI microservice provides production-ready health and instrumentation endpoints:

| Endpoint | Method | Purpose | Kubernetes Probe |
| :--- | :--- | :--- | :--- |
| `/` | `GET` | Service metadata, environment, and version | Client / General |
| `/healthz` | `GET` | Liveness probe verifying process health | `livenessProbe` |
| `/readyz` | `GET` | Readiness probe confirming traffic readiness | `readinessProbe` |
| `/docs` | `GET` | Interactive Swagger API documentation | Developer |

### Test Endpoints via Ingress or Port-Forward

```bash
# Option 1: Port-forward directly to the Kubernetes service
kubectl port-forward svc/cloud-native-api-svc 8080:80

# Option 2: Curl the running service
curl -s http://localhost:8080/
```

**Expected JSON Response:**
```json
{
  "status": "healthy",
  "service": "cloud-native-api",
  "environment": "production",
  "version": "1.0.0"
}
```

```bash
# Verify health probes
curl -s http://localhost:8080/healthz
# Output: {"status":"ok"}

curl -s http://localhost:8080/readyz
# Output: {"ready":true}
```

### Validate Horizontal Pod Autoscaler (HPA)

Simulate traffic load to observe pods scaling from 2 up to 10 replicas:

```bash
# Watch HPA metrics in real time
kubectl get hpa cloud-native-api-hpa --watch

# In a separate terminal, generate synthetic load
kubectl run -i --tty load-generator --rm --image=busybox:latest --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://cloud-native-api-svc; done"
```

---

## 📊 Observability & Monitoring

### Accessing Grafana Dashboards

Grafana is provisioned with ingress disabled for security. Access the interface via port-forwarding:

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Open [http://localhost:3000](http://localhost:3000) in your browser:

| Setting | Value |
| :--- | :--- |
| **Username** | `admin` |
| **Password** | `AdminSecurePassword123!` *(configured in `prometheus-grafana-values.yaml`)* |

> [!TIP]  
> Navigate to **Dashboards > Kubernetes / Compute Resources / Namespace (Pods)** in Grafana to inspect CPU, Memory, and Network I/O of `cloud-native-api`.

### Accessing Prometheus UI

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```
Open [http://localhost:9090](http://localhost:9090) to run PromQL queries such as:
```promql
sum(rate(container_cpu_usage_seconds_total{container="api"}[5m])) by (pod)
```

---

## 🛡️ Security & Resilience Best Practices

- **Zero-Trust Non-Root Containers**: Docker image enforces `USER 10001:10001`. The Kubernetes pod security context enforces `runAsNonRoot: true`, preventing privilege escalation.
- **Private Subnet Isolation**: EKS worker nodes run exclusively in private subnets with no public IPs; ingress traffic passes through controlled NAT gateways and public ALBs.
- **Automated CVE Gatekeeping**: Aqua Trivy scans local container images in CI before any push to Amazon ECR occurs.
- **Zero-Downtime Rollouts**: Deployment defines `maxSurge: 1` and `maxUnavailable: 0` alongside fine-tuned `initialDelaySeconds` and timeout thresholds on probes.
- **Least-Privilege IAM**: Granular AWS IAM roles for the EKS control plane and worker nodes with OIDC integration for IAM Roles for Service Accounts (IRSA).

---

## 🧹 Teardown & Cleanup

> [!WARNING]  
> Always tear down Kubernetes Load Balancers and ingress resources **before** executing `terraform destroy` to prevent orphaned AWS resources and unexpected cloud charges.

```bash
# 1. Uninstall Helm releases (releases AWS Load Balancers)
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall prometheus-stack -n monitoring

# 2. Delete application workloads
kubectl delete -f k8s/ingress.yaml --ignore-not-found
kubectl delete -f k8s/hpa.yaml --ignore-not-found
kubectl delete -f k8s/service.yaml --ignore-not-found
kubectl delete -f k8s/deployment.yaml --ignore-not-found

# 3. Empty the Amazon ECR repository (required for Terraform deletion)
aws ecr batch-delete-image \
  --region ap-south-1 \
  --repository-name cloud-native-api \
  --image-ids "$(aws ecr list-images --region ap-south-1 --repository-name cloud-native-api --query 'imageIds[*]' --output json)" 2>/dev/null || true

# 4. Destroy Terraform-managed infrastructure
cd terraform
terraform destroy --auto-approve
```