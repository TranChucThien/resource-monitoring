import psutil
import socket
from flask import Flask, render_template

app = Flask(__name__)

def get_host_ip():
    try:
        # Tạo socket UDP kết nối đến 8.8.8.8 (Google DNS) cổng 80 để lấy IP interface mạng đang dùng
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"  # fallback nếu lấy IP không được

@app.route("/health")
def health():
    return {"status": "healthy"}, 200

@app.route("/")
def index():
    cpu_metric = psutil.cpu_percent(interval=1)
    mem_metric = psutil.virtual_memory().percent
    host_ip = get_host_ip()
    print("Host IP:", host_ip)
    Message = None
    if cpu_metric > 80 or mem_metric > 80:
        Message = "High CPU or Memory Detected, scale up!!!"
    return render_template("index.html", cpu_metric=cpu_metric, mem_metric=mem_metric, message=Message, host_ip=host_ip)

if __name__=='__main__':
    app.run(debug=True, host = '0.0.0.0')