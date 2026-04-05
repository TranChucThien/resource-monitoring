# 🚀 Hướng dẫn chạy source — DevOps Case Study

---

## 📋 Prerequisites (Cài đặt trước)

| Tool | Mục đích | Cài đặt |
|------|----------|---------|
| Docker | Build & run containers | https://docs.docker.com/get-docker/ |
| Docker Compose | Chạy multi-container | Đi kèm Docker Desktop |
| kubectl | Quản lý K8s cluster | https://kubernetes.io/docs/tasks/tools/ |
| Helm 3 | Deploy K8s bằng chart | https://helm.sh/docs/intro/install/ |
| minikube | K8s local cluster | https://minikube.sigs.k8s.io/docs/start/ |

Kiểm tra đã cài đủ:

```bash
docker --version
docker compose version
kubectl version --client
helm version
minikube version
```

---

## Phần 1 — Chạy Demo App standalone

> Flask Python app hiển thị CPU & Memory usage real-time.

```bash
cd app
pip install -r requirements.txt
flask run --host=0.0.0.0
```

Mở browser: http://localhost:5000 → thấy Plotly gauge dashboard.

Dừng app: `Ctrl + C`

---

## Phần 2 — Chạy bằng Docker Compose (Jenkins + Agent + App)

### 2.1 Start services

```bash
docker compose up -d
```

### 2.2 Kiểm tra services

```bash
docker compose ps
```

| Container | Port | URL |
|-----------|------|-----|
| jenkins | 8080 | http://localhost:8080 |
| jenkins-agent | — | Kết nối tới Jenkins qua host network |
| demo-app | 5000 | http://localhost:5000 |

### 2.3 Truy cập Jenkins

Mở http://localhost:8080

> Setup Wizard đã tắt (`runSetupWizard=false`). Nếu cần password lần đầu:
> ```bash
> docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
> ```

### 2.4 Dừng services

```bash
docker compose down          # Dừng + xóa container
docker compose down -v       # Dừng + xóa cả volume (reset Jenkins data)
```

---

## Phần 3 — Deploy lên Kubernetes bằng Helm (Task 0) ⚠️ BẮT BUỘC

### 3.1 Khởi động minikube

```bash
minikube start
kubectl cluster-info
kubectl get nodes
```

### 3.2 Deploy bằng Helm (OCI registry)

```bash
# Lần đầu install
helm install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0

# Kiểm tra
kubectl get pods
kubectl get svc
```

### 3.3 Truy cập app trên K8s

```bash
# Port-forward
kubectl port-forward svc/resource-monitoring-app-service 5000:80

# Hoặc dùng LoadBalancer
minikube tunnel
# Truy cập qua EXTERNAL-IP của *-lb-service
```

### 3.4 Upgrade khi có image mới

```bash
helm upgrade my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0 \
  --set app.image.tag=v2
```

### 3.5 Rollback

```bash
helm history my-monitoring-app
helm rollback my-monitoring-app          # về revision trước
helm rollback my-monitoring-app 1        # về revision cụ thể
```

### 3.6 Scale

```bash
helm upgrade my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0 \
  --set app.replicaCount=5

# Hoặc kubectl
kubectl scale deployment/resource-monitoring-app-deployment --replicas=5
```

### 3.7 Cleanup

```bash
helm uninstall my-monitoring-app
minikube stop
minikube delete
```

---

## Phần 4 — Jenkins CI/CD Pipeline (Task 1) ⭐

> Pipeline tự động: checkout → test → build → push Docker Hub → helm upgrade → verify.

### 4.1 Chuẩn bị Jenkins Agent

Jenkins agent là custom Docker image (`jenkins/Dockerfile.agent`) đã cài sẵn:
- Docker CLI, Python + pip + flake8 + pytest, kubectl, Helm 3

Agent chạy `network_mode: host` để truy cập minikube trên `127.0.0.1`.

**Tạo kubeconfig cho agent:**

```bash
# Export kubeconfig từ minikube (certs embedded)
kubectl config view --minify --raw --flatten > jenkins/kubeconfig
```

> ⚠️ File `jenkins/kubeconfig` đã có trong `.gitignore` — không push lên Git.

### 4.2 Khởi động Jenkins

```bash
# Đảm bảo minikube đang chạy
minikube status

# Start Jenkins + Agent + App
docker compose up -d
```

Mở http://localhost:8080

### 4.3 Cài Plugin cần thiết

Vào **Manage Jenkins → Plugins → Available plugins**, cài:

| Plugin | Mục đích |
|--------|----------|
| Pipeline | Chạy Jenkinsfile |
| Git | Checkout source code |
| Docker Pipeline | Build/push Docker image |
| Credentials Binding | Inject credentials vào pipeline |
| Pipeline Stage View | Hiển thị stage visualization |

Restart Jenkins sau khi cài xong.

### 4.4 Thêm Docker Hub Credentials

1. Vào **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**
2. Click **Add Credentials**:

| Field | Giá trị |
|-------|---------|
| Kind | Username with password |
| Username | Docker Hub username (vd: `chucthien03`) |
| Password | Docker Hub **Access Token** (quyền Read & Write) |
| ID | `docker-hub-creds` |
| Description | Docker Hub credentials |

> ⚠️ ID phải đúng `docker-hub-creds` — khớp với `credentialsId` trong Jenkinsfile.

> 💡 Tạo Access Token tại: https://hub.docker.com/settings/security → New Access Token → chọn **Read & Write**

### 4.5 Chuẩn bị Helm release

Pipeline dùng `helm upgrade` (không phải `helm install`), nên cần install release trước lần đầu:

```bash
helm install my-monitoring-app \
  oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app \
  --version 0.2.0
```

### 4.6 Tạo Pipeline Job

1. Từ Dashboard → **New Item**
2. Nhập tên: `resource-monitoring-pipeline`
3. Chọn **Pipeline** → OK
4. Trong tab **Pipeline**:

| Field | Giá trị |
|-------|---------|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/TranChucThien/resource-monitoring.git` |
| Branch | `*/main` |
| Script Path | `Jenkinsfile` |

5. Click **Save**

### 4.7 Chạy Pipeline

1. Vào job `resource-monitoring-pipeline`
2. Click **Build Now**
3. Theo dõi tại:
   - **Console Output** — log chi tiết từng step
   - **Stage View** — visualization các stage

### 4.8 Pipeline Flow

```
┌──────────┐    ┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐    ┌────────┐
│ Checkout │───▶│ Test ║ Lint     │───▶│ Docker Build │───▶│ Docker Push │───▶│ Helm Upgrade │───▶│ Verify │
│          │    │   (parallel)    │    │              │    │             │    │              │    │        │
└──────────┘    └─────────────────┘    └──────────────┘    └─────────────┘    └──────────────┘    └────────┘
                                                                                    │
                                                                              ┌─────▼──────┐
                                                                              │  Rollback  │ ← nếu fail
                                                                              └────────────┘
```

| Stage | Lệnh chính | Mô tả |
|-------|------------|--------|
| Checkout | `checkout scm` | Pull code từ Git |
| Test | `pytest tests/` | Chạy unit test (parallel) |
| Lint | `flake8 app.py` | Kiểm tra code style (parallel) |
| Docker Build | `docker build -t chucthien03/resource-monitoring-app:v${BUILD_NUMBER}` | Build image với tag theo build number |
| Docker Push | `docker push` | Push image lên Docker Hub |
| Deploy to K8s | `helm upgrade ... --set app.image.tag=v${BUILD_NUMBER}` | Helm upgrade từ OCI registry |
| Verify | `kubectl rollout status --timeout=120s` | Chờ pods ready |

### 4.9 Kết quả mong đợi

**Build thành công:**

```
✅ Pipeline SUCCESS — chucthien03/resource-monitoring-app:v20 deployed
```

Stage View hiển thị tất cả stage xanh (green).

**Build thất bại:**

```
❌ Pipeline FAILED — Rolling back Helm release
```

Tự động chạy `helm rollback my-monitoring-app`.

### 4.10 Jenkinsfile giải thích

```groovy
pipeline {
  agent any

  environment {
    IMAGE_NAME   = "chucthien03/resource-monitoring-app"
    IMAGE_TAG    = "v${env.BUILD_NUMBER}"        // v1, v2, v3...
    HELM_RELEASE = "my-monitoring-app"
    HELM_CHART   = "oci://ghcr.io/tranchucthien/helm-charts/resource-monitoring-app"
    HELM_VERSION = "0.2.0"
  }

  stages {
    // Checkout → Test+Lint (parallel) → Docker Build → Push → Helm Upgrade → Verify
  }

  post {
    success { echo "✅ ..." }
    failure {
      // Tự động rollback khi bất kỳ stage nào fail
      sh "helm rollback ${HELM_RELEASE} || true"
    }
    always {
      sh 'docker logout || true'    // Cleanup credentials
    }
  }
}
```

Điểm quan trọng:
- `IMAGE_TAG = "v${env.BUILD_NUMBER}"` → mỗi build tạo tag mới (v1, v2, v3...)
- `helm upgrade` (không có `--install`) → release phải install trước (bước 4.5)
- `helm upgrade` không dùng `--wait` → return ngay, stage Verify kiểm tra rollout
- `post { failure {} }` → tự động `helm rollback` khi pipeline fail
- Parallel stages: Test + Lint chạy đồng thời, tiết kiệm thời gian

---

## 🔍 Troubleshooting

### Docker Compose

| Lỗi | Fix |
|-----|-----|
| Port 8080 already in use | `sudo lsof -i :8080` rồi kill hoặc đổi port |
| demo-app build fail | `cd app && pip install -r requirements.txt` test trước |
| jenkins-agent không connect | Kiểm tra `JENKINS_SECRET` trong `.env` khớp với agent node trên Jenkins |

### Kubernetes / Helm

| Lỗi | Fix |
|-----|-----|
| `ImagePullBackOff` | Kiểm tra image tag tồn tại trên Docker Hub |
| `CrashLoopBackOff` | `kubectl logs <pod-name>` xem lỗi |
| Pod `Pending` | `kubectl describe pod <pod>`, tăng minikube resource |
| Helm upgrade fail | `helm history my-monitoring-app`, rollback nếu stuck `pending-upgrade` |
| Service không truy cập | `kubectl get ep`, kiểm tra selector match labels |

### Jenkins Pipeline

| Lỗi | Fix |
|-----|-----|
| `docker: command not found` | Dùng custom agent image (`jenkins/Dockerfile.agent`) |
| `pip: not found` | Rebuild agent: `docker compose build jenkins-agent` |
| `permission denied` docker.sock | Agent phải chạy `user: root` trong docker-compose |
| `Kubernetes cluster unreachable` | Kiểm tra `jenkins/kubeconfig` đúng, agent dùng `network_mode: host` |
| Credentials not found | Kiểm tra ID credentials = `docker-hub-creds` |
| Docker push `insufficient scopes` | Tạo lại Access Token với quyền **Read & Write** |
| Helm `pending-upgrade` stuck | `helm rollback my-monitoring-app` rồi chạy lại |

---

## 📝 Thứ tự chạy demo khuyến nghị

```
1. minikube start                              → Khởi tạo K8s cluster
2. helm install my-monitoring-app ...          → Deploy app lần đầu
3. docker compose up -d                        → Start Jenkins + Agent + App
4. Setup Jenkins (plugins, credentials, job)   → Cấu hình pipeline
5. Build Now                                   → Chạy pipeline
```
