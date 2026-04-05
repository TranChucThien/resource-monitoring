#!/bin/sh
set -e

# Nếu biến API_BASE_URL không có thì gán mặc định
API_BASE_URL=${API_BASE_URL:-http://localhost:8000}

echo "{
  \"API_BASE_URL\": \"${API_BASE_URL}\"
}" > /usr/share/nginx/html/config.json

# Chạy nginx
exec nginx -g 'daemon off;'
