# DevOps Case Study – Practical Exercise

## 📋 Tổng quan

Project demo CI/CD pipeline hoàn chỉnh với Jenkins, Docker, Kubernetes (deploy bằng Helm), bao gồm monitoring và Infrastructure as Code.

Demo application: **Resource Monitoring App** – Flask Python app hiển thị CPU & Memory usage real-time qua Plotly gauges.

 

### 1. Khởi động Jenkins + App (local)

```bash
docker-compose up -d
```

| Service | URL |
|---------|-----|
| Jenkins UI | http://localhost:8080 |
| Demo App | http://localhost:5000 |

### 2. Deploy lên Kubernetes bằng Helm

```bash
# Khởi tạo cluster
minikube start

# Deploy bằng Helm (từ OCI registry)
helm install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0

# Kiểm tra
kubectl get pods
kubectl get svc
```

### 3. Truy cập app trên K8s

```bash
# Port-forward
kubectl port-forward svc/resource-monitoring-app-service 5000:80

# Hoặc dùng LoadBalancer (minikube tunnel)
minikube tunnel
# Truy cập qua EXTERNAL-IP của *-lb-service
```


## 🔧 Task 0 – Kubernetes Deployment bằng Helm 

### Tại sao chọn Helm thay vì kubectl apply?

| Tiêu chí | `kubectl apply` | Helm |
|-----------|-----------------|------|
| Quản lý release | Không có | Có version, history, rollback |
| Template hóa | Không | Dùng Go template, linh hoạt |
| Tái sử dụng | Copy-paste YAML | 1 chart dùng cho nhiều env |
| Upgrade/Rollback | Manual `sed` + apply | `helm upgrade` / `helm rollback` |
| Dependency | Tự quản lý | Chart dependencies tự động |

→ **Kết luận**: Helm phù hợp hơn cho project có nhiều environment và cần quản lý release history.

### Helm Chart Structure

```
app/infra/resource-monitoring-app/
├── Chart.yaml          # Chart metadata (name, version)
├── values.yaml         # Default values (replicas, image, ports)
├── .helmignore
└── templates/
    ├── _helpers.tpl    # Template helpers (name, labels)
    ├── deployment.yaml # Deployment resource
    ├── service.yaml    # ClusterIP + LoadBalancer services
    └── tests/
        └── test-connection.yaml
```

### values.yaml – Cấu hình mặc định

```yaml
app:
  replicaCount: 3
  image:
    repository: "chucthien03/resource-monitoring-app"
    tag: "v2"
    pullPolicy: "IfNotPresent"
  containerPort: 5000
  service:
    port: 80
```

### Các lệnh Helm thường dùng

```bash
# Install từ OCI registry
helm install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0

# Upgrade (đổi image tag)
helm upgrade --install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0 \
  --set app.image.tag=v3

# Rollback về revision trước
helm rollback my-monitoring-app

# Rollback về revision cụ thể
helm history my-monitoring-app
helm rollback my-monitoring-app 2

# Uninstall
helm uninstall my-monitoring-app
```

### Image Versioning

- Jenkins pipeline tag image theo `BUILD_NUMBER`: `resource-monitoring-app:v${BUILD_NUMBER}`
- Helm upgrade dùng `--set app.image.tag=v${BUILD_NUMBER}`
- **Không dùng `latest`** trong production

### Scale Application

```bash
# Scale qua Helm
helm upgrade my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0 \
  --set app.replicaCount=5

# Hoặc kubectl trực tiếp
kubectl scale deployment/resource-monitoring-app-deployment --replicas=5

# Autoscaling (HPA)
kubectl autoscale deployment/resource-monitoring-app-deployment \
  --min=2 --max=10 --cpu-percent=70
```

---

## 🔧 Task 1 – Jenkins CI/CD Pipeline

### Pipeline Structure

```
Checkout → Lint + Test (parallel) → Docker Build → Push Docker Hub → Helm Upgrade (OCI) → Verify
```

### Flow chi tiết

| Stage | Mô tả |
|-------|--------|
| Checkout | Pull source code từ Git |
| Build & Test | **Parallel**: chạy `pytest` + `flake8` cùng lúc |
| Docker Build | Build image `chucthien03/resource-monitoring-app:v<BUILD_NUMBER>` |
| Docker Push | Push image lên Docker Hub |
| Deploy to K8s | `helm upgrade` từ OCI registry (release đã install sẵn) |
| Verify | `kubectl rollout status` kiểm tra deployment |

### Helm Chart từ OCI Registry

Chart đã publish lên GitHub Container Registry:

```bash
# Lần đầu install (chạy thủ công 1 lần trước khi dùng pipeline)
helm install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0

# Pipeline tự động upgrade khi có image mới
helm upgrade my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0 \
  --set app.image.tag=v${BUILD_NUMBER}
```

### Pipeline tích hợp Helm (Jenkinsfile)

```groovy
environment {
  IMAGE_NAME   = "chucthien03/resource-monitoring-app"
  IMAGE_TAG    = "v${env.BUILD_NUMBER}"
  HELM_RELEASE = "my-monitoring-app"
  HELM_CHART   = "oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app"
  HELM_VERSION = "0.2.0"
}

stage('Deploy to K8s') {
  steps {
    sh """
      helm upgrade ${HELM_RELEASE} ${HELM_CHART} \
        --version ${HELM_VERSION} \
        --set app.image.tag=${IMAGE_TAG}
    """
  }
}

stage('Verify') {
  steps {
    sh """
      kubectl rollout status deployment/resource-monitoring-app-deployment --timeout=120s
      kubectl get pods -l app=resource-monitoring-app
    """
  }
}
```

### Rollback Strategy

```bash
# Tự động rollback khi pipeline fail (trong post { failure {} })
helm rollback my-monitoring-app

# Manual rollback về revision cụ thể
helm history my-monitoring-app
helm rollback my-monitoring-app <REVISION>
```

- `post { failure { } }` → tự động `helm rollback`

### Error Handling
- Parallel stages: test fail không block lint và ngược lại
- `post { failure { } }` → `helm rollback` + `docker logout`
- Verify stage: `kubectl rollout status --timeout=120s` kiểm tra pods ready

### Jenkins Agent

Custom agent image (`jenkins/Dockerfile.agent`) cài sẵn:
- Docker CLI — build & push image
- Python + pip + flake8 + pytest — test & lint
- kubectl — quản lý K8s
- Helm 3 — deploy chart

Agent chạy `network_mode: host` để truy cập minikube trên `127.0.0.1`, kubeconfig mount từ host vào `/root/.kube/config`.

---

## 🔧 Task 4 – Pipeline Optimization

### Scenario

Pipeline hiện tại:
- Build mất ~25 phút
- Docker build thường fail
- Developers phàn nàn deployment chậm

### Phân tích nguyên nhân

| # | Vấn đề | Nguyên nhân gốc |
|---|--------|----------------|
| 1 | `pip install` chạy lại mỗi build | Không cache dependencies, tải lại toàn bộ packages |
| 2 | Test + Lint chạy tuần tự | Lãng phí thời gian khi 2 stage độc lập |
| 3 | Docker build lại từ đầu | Layer cache bị invalidate do COPY thứ tự sai |
| 4 | Docker build fail ngẫu nhiên | Base image quá nặng, network timeout khi pull |
| 5 | Deploy chậm | Helm `--wait` chờ pods pull image từ registry |

### 5 cách tối ưu đã áp dụng

#### 1. Parallel Stages — Test + Lint chạy đồng thời

**Trước:** Test xong mới chạy Lint (tuần tự)

**Sau:** Chạy song song, tiết kiệm ~50% thời gian stage này

```groovy
stage('Build & Test') {
  parallel {
    stage('Test') {
      steps {
        dir('app') {
          sh 'pip install --break-system-packages -r requirements.txt'
          sh 'python -m pytest tests/ || echo "No tests found, skipping"'
        }
      }
    }
    stage('Lint') {
      steps {
        dir('app') {
          sh 'flake8 app.py --max-line-length=120 || true'
        }
      }
    }
  }
}
```

#### 2. Dependency Caching — Pre-install trong Agent image

**Trước:** Mỗi build chạy `pip install flake8 pytest`

**Sau:** `flake8`, `pytest` đã cài sẵn trong agent image, chỉ install app dependencies

```dockerfile
# jenkins/Dockerfile.agent
RUN pip3 install --break-system-packages flake8 pytest
```

Kết quả: Lint stage không cần install gì, chạy ngay.

#### 3. Optimized Dockerfile — Giảm image size + tăng build speed

**Trước (`Dockerfile`):** Dùng `python:3.9.17-slim-buster`, chạy root

**Sau (`Dockerfile_op`):** Dùng `python:3.9-slim`, non-root user, layer cache tối ưu

```dockerfile
FROM python:3.9-slim
WORKDIR /app

# COPY requirements.txt TRƯỚC → layer cache khi code thay đổi
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# COPY source SAU → chỉ rebuild layer này khi code thay đổi
COPY . .

# Non-root user (bảo mật)
RUN adduser --system appuser
USER appuser

ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_APP=app.py
EXPOSE 5000
ENTRYPOINT ["flask", "run"]
```

Tại sao nhanh hơn:
- `COPY requirements.txt` trước `COPY . .` → khi chỉ sửa code (không đổi dependencies), Docker dùng lại layer cache của `pip install`
- `--no-cache-dir` → giảm image size
- `python:3.9-slim` → nhỏ hơn `buster`, pull/push nhanh hơn

#### 4. Docker Layer Caching — Tận dụng cache giữa các build

Vì agent dùng `network_mode: host` và mount Docker socket từ host, Docker layer cache được giữ lại giữa các build:

```
v15: digest: sha256:f7c051efc458... size: 2200
8ab1a8ef86df: Layer already exists    ← cache hit
53eb728c4c0a: Layer already exists    ← cache hit
c8f6b54339a8: Layer already exists    ← cache hit
```

Chỉ push layer thay đổi, không push lại toàn bộ image.

---

## 🔧 Task 2 – Infrastructure as Code (Terraform)

### Kiến trúc AWS 3-Tier

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              AWS VPC (10.0.0.0/16)                              │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  Web Tier (Public Subnets)                                                  │  │
│  │  ┌─────────────────┐   ┌────────────────────────────────────────────────┐  │  │
│  │  │  Bastion Host  │   │  ALB (Internet-facing)                            │  │  │
│  │  │  (SSH Jump)    │   │  :80 → Frontend TG  |  :8000 → Backend TG     │  │  │
│  │  └─────────────────┘   └────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  App Tier (Private Subnets)                                                 │  │
│  │  ┌───────────────────────────────┐   ┌───────────────────────────────┐  │  │
│  │  │  ASG Frontend (Docker)       │   │  ASG Backend (Docker)        │  │  │
│  │  │  min=1, max=3, :3000        │   │  min=1, max=3, :8000        │  │  │
│  │  └───────────────────────────────┘   └───────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                                │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  Data Tier (Private Subnets)                                                │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │  │
│  │  │  EC2 MongoDB (Docker Compose)                                          │  │  │
│  │  │  :27017 ← chỉ cho phép từ App Tier SG                                  │  │  │
│  │  └──────────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Cấu trúc Terraform

```
terraform-aws-3-tier-architecture/
├── terraform-code/
│   ├── main.tf                    # Root module — gọi các module con
│   ├── variables.tf               # Tất cả variables (region, env, compute, ASG...)
│   ├── output.tf                  # ALB DNS, Bastion IP
│   ├── backend/
│   │   └── main.tf                # S3 backend cho remote state
│   ├── environments/              # ⭐ tfvars theo environment
│   │   ├── dev.tfvars             # t2.micro, ASG 1–2
│   │   ├── staging.tfvars         # t3.small, ASG 1–4
│   │   └── prod.tfvars            # t3.medium, ASG 2–6, SSH restricted
│   ├── templates/
│   │   ├── user_data_fe.sh        # Bootstrap frontend (Docker)
│   │   └── user_data_be.sh        # Bootstrap backend (Docker)
│   └── modules/
│       ├── vpc/                   # VPC, Subnets, NAT, IGW, Route Tables
│       ├── securitygroup/         # Security Groups (Web/App/DB)
│       ├── ec2/                   # EC2 instances (Bastion, DB)
│       ├── asg/                   # Auto Scaling Groups (FE, BE)
│       ├── load_balancer/         # Application Load Balancer
│       ├── target_group/          # Target Groups (FE :3000, BE :8000)
│       └── s3/                    # S3 bucket cho Terraform state
└── application/                   # Docker Compose apps
    ├── frontend/                  # Frontend (Nginx + static)
    ├── backend/                   # Backend (Python FastAPI)
    └── db/                        # MongoDB
```

### Modular Design

Tất cả resources được tổ chức thành **reusable modules**:

| Module | Resources | Mục đích |
|--------|-----------|----------|
| `vpc` | VPC, Subnets (public/private), IGW, NAT, Route Tables | Network layer |
| `securitygroup` | Security Groups với ingress rules linh hoạt | Firewall rules |
| `ec2` | EC2 instances với user_data | Bastion Host, DB server |
| `asg` | Launch Template + Auto Scaling Group | Frontend/Backend auto-scale |
| `load_balancer` | ALB với multiple listeners | Traffic routing |
| `target_group` | Target Groups với health check | ALB → EC2 mapping |
| `s3` | S3 bucket | Terraform remote state |

### Quản lý Environment (dev/staging/prod)

Mỗi environment có file `.tfvars` riêng trong `environments/`:

```bash
# Dev
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform apply -var-file=environments/staging.tfvars

# Prod
terraform apply -var-file=environments/prod.tfvars
```

Sự khác biệt giữa các env:

| Config | Dev | Staging | Prod |
|--------|-----|---------|------|
| `instance_type` | t2.micro | t3.small | t3.medium |
| `asg_min` | 1 | 1 | 2 |
| `asg_desired` | 1 | 2 | 3 |
| `asg_max` | 2 | 4 | 6 |
| `ssh_allowed_cidr` | 0.0.0.0/0 | 0.0.0.0/0 | Office IP only |

Tất cả resource names có prefix `${project_name}-${environment}-*` → không conflict giữa các env.

### Đảm bảo Infrastructure Reproducible

| Giải pháp | Chi tiết |
|-----------|----------|
| **Remote State (S3)** | State file lưu trên S3 với encryption, lock bằng `use_lockfile` |
| **Modular code** | Mỗi component là 1 module, tái sử dụng cho nhiều env |
| **Environment tfvars** | `environments/*.tfvars` — cùng code, khác config theo env |
| **User data templates** | `templatefile()` inject biến động (DB IP, ALB DNS) vào bootstrap script |
| **Version pinning** | Provider version cố định, AMI ID explicit |

### Tránh Config Drift

| Giải pháp | Chi tiết |
|-----------|----------|
| **Remote state + locking** | S3 backend với lock tránh 2 người apply đồng thời |
| **Mọi thay đổi qua Terraform** | Không sửa manual trên AWS Console |
| **`terraform plan` trước apply** | Review changes trước khi áp dụng |
| **Git version control** | Mọi thay đổi IaC đều qua PR review |
| **State refresh** | `terraform refresh` phát hiện drift giữa state và thực tế |

### Security

- **Bastion Host**: SSH vào private instances qua bastion ở public subnet
- **Security Groups**: App Tier chỉ nhận traffic từ ALB SG, DB Tier chỉ nhận từ App SG
- **Private Subnets**: App và DB không expose ra internet, truy cập internet qua NAT Gateway
- **S3 State Encryption**: Terraform state được encrypt trên S3

### Các lệnh Terraform

```bash
cd terraform-aws-3-tier-architecture/terraform-code

# Tạo S3 backend trước
cd backend && terraform init && terraform apply && cd ..

# Init + Plan + Apply
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Xem outputs
terraform output

# Deploy sang env khác
terraform apply -var-file=environments/prod.tfvars

# Destroy
terraform destroy -var-file=environments/dev.tfvars
```

---

