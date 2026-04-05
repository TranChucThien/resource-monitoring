# 🔧 Troubleshooting Notes

Các lỗi gặp phải khi setup CI/CD pipeline và cách fix.

---

## 1. Git — Embedded repository warning

```
warning: adding embedded git repository: app
```

**Nguyên nhân:** Thư mục `app/` chứa `.git/` từ repo cũ.

**Fix:**
```bash
rm -rf app/.git app/.github
git rm --cached app
git add .
```

---

## 2. Jenkins Agent — `docker: command not found`

**Nguyên nhân:** Agent mặc định (`jenkins/inbound-agent`) không có Docker CLI.

**Fix:** Tạo custom agent image (`jenkins/Dockerfile.agent`) cài Docker CLI, kubectl, Helm, Python.

---

## 3. Jenkins Agent — `pip: not found`

**Nguyên nhân:** Agent chưa cài Python.

**Fix:** Thêm vào `Dockerfile.agent`:
```dockerfile
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv
```

---

## 4. pip — `externally managed environment`

**Nguyên nhân:** Debian mới chặn `pip install` system-wide (PEP 668).

**Fix:** Dùng `--break-system-packages`:
```dockerfile
RUN pip3 install --break-system-packages flake8 pytest
```

Jenkinsfile cũng cần:
```groovy
sh 'pip install --break-system-packages -r requirements.txt'
```

---

## 5. Docker Build — `permission denied` docker.sock

**Nguyên nhân:** User `jenkins` không có quyền truy cập `/var/run/docker.sock`.

**Fix:** Chạy agent với `user: root` trong `docker-compose.yml`:
```yaml
jenkins-agent:
  user: root
```

---

## 6. Docker Push — `insufficient scopes`

**Nguyên nhân:** Docker Hub Access Token chỉ có quyền Read-only.

**Fix:** Tạo token mới với quyền **Read & Write** tại https://hub.docker.com/settings/security

---

## 7. Helm — `Kubernetes cluster unreachable: localhost:8080`

**Nguyên nhân:** Agent chạy trong Docker container, không tìm thấy kubeconfig.

**Fix:** Mount kubeconfig vào `/root/.kube/config` (vì agent chạy root):
```yaml
volumes:
  - ./jenkins/kubeconfig:/root/.kube/config:ro
```

---

## 8. Helm — `cluster unreachable: 172.x.x.x:32776 connection refused`

**Nguyên nhân:** Minikube API chỉ listen trên `127.0.0.1`, container không thể truy cập IP host.

**Fix:** Agent dùng `network_mode: host`:
```yaml
jenkins-agent:
  network_mode: host
  environment:
    - JENKINS_URL=http://127.0.0.1:8080
```

Kubeconfig giữ nguyên `server: https://127.0.0.1:<port>`.

---

## 9. Helm — `--wait` timeout / `pending-upgrade` stuck

**Nguyên nhân:** `--wait` chờ tất cả pods ready, minikube pull image từ Docker Hub chậm → timeout → release stuck `pending-upgrade`.

**Fix:**
1. Bỏ `--wait` khỏi `helm upgrade`, dùng `kubectl rollout status` ở stage Verify
2. Nếu release stuck:
```bash
helm rollback my-monitoring-app
```

---

## 10. Helm — pull chart OCI mỗi lần upgrade

**Nguyên nhân:** `helm upgrade` từ OCI registry luôn pull chart về.

**Ghi chú:** Không dùng `--wait` nên thời gian pull chart (~2s) chấp nhận được. Nếu cần nhanh hơn có thể dùng local chart, nhưng yêu cầu bài dùng OCI registry.
