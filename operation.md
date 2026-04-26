# Hướng Dẫn Vận Hành

## Mục Lục

1. [Yêu cầu hệ thống](#1-yêu-cầu-hệ-thống)
2. [Docker Compose — Hạ tầng Orchestrator](#2-docker-compose--hạ-tầng-orchestrator)
3. [Cấu hình biến môi trường (ENV)](#3-cấu-hình-biến-môi-trường-env)
4. [Chạy Orchestrator (uv)](#4-chạy-orchestrator-uv)
5. [Chạy Worker trên Jetson Nano (uv)](#5-chạy-worker-trên-jetson-nano-uv)
6. [Chạy Dashboard](#6-chạy-dashboard)
7. [Cài đặt Mosquitto MQTT](#7-cài-đặt-mosquitto-mqtt)

---

## 1. Yêu Cầu Hệ Thống

### Máy chủ Orchestrator

| Thành phần | Yêu cầu                                                                              |
| ---------- | ------------------------------------------------------------------------------------ |
| OS         | Ubuntu 20.04+ / macOS                                                                |
| Python     | ≥ 3.10                                                                               |
| Docker     | ≥ 20.x + Docker Compose v2                                                           |
| `uv`       | Package manager ([cài đặt](https://docs.astral.sh/uv/getting-started/installation/)) |
| Mosquitto  | MQTT Broker (cài trên host hoặc Docker)                                              |
| RAM        | ≥ 4GB                                                                                |

### Thiết bị biên Worker

| Thành phần | Yêu cầu                                           |
| ---------- | ------------------------------------------------- |
| Phần cứng  | NVIDIA Jetson Nano (JetPack 4.x)                  |
| Python     | 3.6 (hệ thống JetPack)                            |
| `uv`       | Package manager                                   |
| TensorRT   | Có sẵn trong JetPack                              |
| Cảm biến   | USB Fingerprint Sensor (VID: 0x0483, PID: 0x5720) |

### Dashboard

| Thành phần | Yêu cầu         |
| ---------- | --------------- |
| Node.js    | ≥ 18            |
| pnpm       | Package manager |

---

## 2. Docker Compose — Hạ Tầng Orchestrator

File `docker-compose.yml` tại thư mục gốc project chứa **3 service**:

| Service             | Image                    | Port                           | Vai trò                                 |
| ------------------- | ------------------------ | ------------------------------ | --------------------------------------- |
| `fingerprint-db`    | `pgvector/pgvector:pg16` | `5433:5432`                    | PostgreSQL + pgvector — Master database |
| `fingerprint-minio` | `minio/minio:latest`     | `9000` (API), `9001` (Console) | Object storage cho model & ảnh          |
| `minio-init`        | `minio/mc:latest`        | —                              | Tự động tạo bucket khi khởi động        |

> **Lưu ý**: Mosquitto MQTT hiện tại được cài trên host, không trong Docker. Nếu muốn chạy trong Docker, bỏ comment phần `fingerprint-mqtt` trong `docker-compose.yml`.

### Khởi động hạ tầng

```bash
# Tại thư mục gốc project (chứa docker-compose.yml)
docker compose up -d
```

### Kiểm tra trạng thái

```bash
docker compose ps
```

Kết quả mong đợi:

```
NAME                        STATUS
fingerprint-db              running (healthy)
fingerprint-minio           running (healthy)
fingerprint-minio-init      exited (0)    ← bình thường, chỉ chạy 1 lần
```

### Truy cập

| Service       | URL                                                            |
| ------------- | -------------------------------------------------------------- |
| MinIO Console | http://localhost:9001 (login: `minioadmin` / `minioadmin123`)  |
| PostgreSQL    | `localhost:5433` (user: `fingerprint`, pass: `fingerprint123`) |

### Dừng hạ tầng

```bash
docker compose down         # giữ data
docker compose down -v      # xoá cả volume (mất data!)
```

### Cấu trúc MinIO Buckets

```
fingerprint-models/
├── embedding/
│   └── embedding_v1/model.onnx
├── matching/
│   └── matching_v1/model.onnx
└── pad/
    └── pad_v1/model.onnx

fingerprint-images/          ← flat, chứa tất cả ảnh vân tay
```

---

## 3. Cấu Hình Biến Môi Trường (ENV)

### 3.1 Biến môi trường chung (`.env` gốc — Docker Compose)

```env
DB_USER=fingerprint
DB_PASSWORD=fingerprint123
DB_NAME=fingerprint_db
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
```

### 3.2 Orchestrator (`fingerprint_orchestrator/.env`)

| Biến                       | Mô tả                                         | Giá trị mặc định      |
| -------------------------- | --------------------------------------------- | --------------------- |
| `APP_HOST`                 | IP bind server                                | `0.0.0.0`             |
| `APP_PORT`                 | Port API                                      | `8001`                |
| `MQTT_BROKER_HOST`         | IP MQTT broker                                | `localhost`           |
| `MQTT_BROKER_PORT`         | Port MQTT                                     | `1883`                |
| `MQTT_CLIENT_ID`           | Client ID MQTT                                | `orchestrator-main`   |
| `WORKER_HEARTBEAT_TIMEOUT` | Timeout (giây) đánh dấu worker offline        | `30`                  |
| `MINIO_ENDPOINT`           | MinIO API endpoint                            | `localhost:9000`      |
| `MINIO_PUBLIC_ENDPOINT`    | IP public cho worker download (Tailscale/LAN) | `100.100.108.30:9000` |
| `MINIO_ACCESS_KEY`         | MinIO username                                | `minioadmin`          |
| `MINIO_SECRET_KEY`         | MinIO password                                | `minioadmin123`       |
| `MINIO_BUCKET_MODELS`      | Bucket chứa model                             | `fingerprint-models`  |
| `MINIO_BUCKET_IMAGES`      | Bucket chứa ảnh                               | `fingerprint-images`  |
| `DB_HOST`                  | PostgreSQL host                               | `localhost`           |
| `DB_PORT`                  | PostgreSQL port                               | `5433`                |
| `DB_USER`                  | PostgreSQL user                               | `fingerprint`         |
| `DB_PASSWORD`              | PostgreSQL password                           | `fingerprint123`      |
| `DB_NAME`                  | PostgreSQL database                           | `fingerprint_db`      |

> **QUAN TRỌNG**: `MINIO_PUBLIC_ENDPOINT` phải là IP mà **worker có thể truy cập được** (ví dụ: IP Tailscale, IP LAN). Worker dùng URL này để tải model và upload ảnh.

### 3.3 Worker (`fingerprint-jetson-nano/.env`)

| Biến                        | Mô tả                                       | Giá trị mặc định                          |
| --------------------------- | ------------------------------------------- | ----------------------------------------- |
| `WORKER_DEVICE_ID`          | ID định danh thiết bị (duy nhất mỗi worker) | `JETSON-001`                              |
| `WORKER_HOST`               | IP bind API                                 | `0.0.0.0`                                 |
| `WORKER_PORT`               | Port API                                    | `8000`                                    |
| `WORKER_HOME`               | Đường dẫn gốc project trên Jetson           | `/home/binhan1/fingerprint-jetson-nano`   |
| `WORKER_BACKEND`            | Backend inference (`tensorrt` hoặc `onnx`)  | `tensorrt`                                |
| `WORKER_MODEL_PATH`         | Đường dẫn model inference                   | `models/embedding`                        |
| `WORKER_MODEL_DIR`          | Thư mục chứa tất cả model                   | `models/`                                 |
| `WORKER_DATA_DIR`           | Thư mục dữ liệu                             | `data/`                                   |
| `WORKER_IMAGE_WIDTH`        | Chiều rộng ảnh đầu vào                      | `192`                                     |
| `WORKER_IMAGE_HEIGHT`       | Chiều cao ảnh đầu vào                       | `192`                                     |
| `WORKER_EMBEDDING_DIM`      | Số chiều embedding                          | `512`                                     |
| `WORKER_MQTT_ENABLED`       | Bật/tắt MQTT                                | `true`                                    |
| `WORKER_MQTT_BROKER_HOST`   | IP MQTT broker (IP orchestrator)            | `100.100.108.30`                          |
| `WORKER_MQTT_BROKER_PORT`   | Port MQTT                                   | `1883`                                    |
| `WORKER_HEARTBEAT_INTERVAL` | Chu kỳ heartbeat (giây)                     | `10`                                      |
| `WORKER_DATABASE_URL`       | SQLite connection string                    | `sqlite+aiosqlite:///data/fingerprint.db` |
| `WORKER_SENSOR_VID`         | Vendor ID cảm biến USB                      | `0x0483`                                  |
| `WORKER_SENSOR_PID`         | Product ID cảm biến USB                     | `0x5720`                                  |
| `WORKER_SENSOR_SDK_PATH`    | Đường dẫn SDK cảm biến                      | `/home/binhan1/SDK-Fingerprint-sensor`    |
| `WORKER_ENCRYPTION_KEY`     | Fernet key mã hoá embedding                 | (auto-generate)                           |

**Matching Thresholds** (tuỳ chỉnh nếu cần):

| Biến                                  | Mô tả                     | Mặc định (config.py) |
| ------------------------------------- | ------------------------- | -------------------- |
| `WORKER_VERIFY_THRESHOLD`             | Ngưỡng xác thực 1:1       | `0.96`               |
| `WORKER_IDENTIFY_THRESHOLD`           | Ngưỡng nhận diện 1:N      | `0.95`               |
| `WORKER_IDENTIFY_TOP_K`               | Số kết quả KNN trả về     | `5`                  |
| `WORKER_DUPLICATE_IDENTIFY_THRESHOLD` | Ngưỡng kiểm tra trùng lặp | `0.96`               |

### 3.4 Dashboard (`fingerprint_dashboard/.env`)

| Biến                  | Mô tả                | Giá trị mặc định        |
| --------------------- | -------------------- | ----------------------- |
| `NEXT_PUBLIC_API_URL` | URL orchestrator API | `http://localhost:8001` |

---

## 4. Chạy Orchestrator (uv)

### Cài đặt lần đầu

```bash
cd fingerprint_orchestrator
cp .env.example .env
# Sửa .env theo môi trường thực tế

# Cách 1: Dùng script tự động
chmod +x scripts/setup_orchestrator_env.sh
./scripts/setup_orchestrator_env.sh

# Cách 2: Thủ công
uv venv --python python3 venv
source venv/bin/activate
uv sync --active --no-editable \
  --refresh-package fingerprint-orchestrator \
  --reinstall-package fingerprint-orchestrator
```

### Cập nhật sau git pull

```bash
cd fingerprint_orchestrator
# Không cần tạo lại venv
RECREATE_VENV=0 ./scripts/setup_orchestrator_env.sh

# Hoặc thủ công:
source venv/bin/activate
uv sync --active --no-editable \
  --refresh-package fingerprint-orchestrator \
  --reinstall-package fingerprint-orchestrator
```

### Chạy API Server

```bash
cd fingerprint_orchestrator
source venv/bin/activate
fingerprint-orchestrator-api
# Hoặc: python -m app.main
```

API sẽ chạy tại: `http://0.0.0.0:8001`

### Chạy CLI (giám sát MQTT interactive)

```bash
cd fingerprint_orchestrator
source venv/bin/activate
fingerprint-orchestrator-cli
# Hoặc: python -m app.cli
```

---

## 5. Chạy Worker Trên Jetson Nano (uv)

> **Lưu ý quan trọng**: Worker chạy Python 3.6 (JetPack). Phải dùng `--system-site-packages` để giữ TensorRT, NumPy, OpenCV, PyQt5 từ hệ thống.

### Cài đặt lần đầu

```bash
cd fingerprint-jetson-nano
cp .env.example .env
# Sửa .env — đặc biệt: WORKER_DEVICE_ID, WORKER_MQTT_BROKER_HOST

# Cách 1: Script tự động (khuyến nghị)
chmod +x scripts/setup_jetson_env.sh
./scripts/setup_jetson_env.sh

# Cách 2: Thủ công
uv venv --python /usr/bin/python3 --system-site-packages venv
source venv/bin/activate
uv sync --active --no-editable --extra jetson
```

### Cập nhật sau git pull

```bash
cd fingerprint-jetson-nano

# Cách 1: Script (không tạo lại venv)
SKIP_APT=1 RECREATE_VENV=0 ./scripts/setup_jetson_env.sh

# Cách 2: Thủ công (dùng --inexact để không xoá package Jetson)
source venv/bin/activate
uv sync --active --inexact --no-editable --extra jetson \
  --refresh-package fingerprint-jetson-worker \
  --reinstall-package fingerprint-jetson-worker
```

### Chạy môi trường ONNX (trên PC, không có TensorRT)

```bash
source venv/bin/activate
uv sync --active --inexact --no-editable --extra onnx \
  --refresh-package fingerprint-jetson-worker \
  --reinstall-package fingerprint-jetson-worker
```

### Chạy API Worker

```bash
cd fingerprint-jetson-nano
source venv/bin/activate
fingerprint-worker-api
# Hoặc: python -m app.main
```

API sẽ chạy tại: `http://0.0.0.0:8000`

### Chạy GUI (màn hình cảm ứng)

```bash
fingerprint-worker-gui
```

### Chạy CLI (giám sát MQTT tại worker)

```bash
fingerprint-worker-cli
```

### Chạy như systemd service (production)

```bash
# Tạo file service
sudo nano /etc/systemd/system/fingerprint-worker.service
```

Nội dung file service:

```ini
[Unit]
Description=Fingerprint Worker API
After=network.target

[Service]
Type=simple
User=binhan1
WorkingDirectory=/home/binhan1/fingerprint-jetson-nano
ExecStart=/home/binhan1/fingerprint-jetson-nano/venv/bin/fingerprint-worker-api
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable fingerprint-worker
sudo systemctl start fingerprint-worker

# Kiểm tra log
journalctl -u fingerprint-worker -f
```

### USB Sensor Permission (Jetson Nano)

```bash
# Thêm quyền truy cập USB cho user
sudo usermod -aG plugdev $USER

# Tạo udev rule
sudo nano /etc/udev/rules.d/99-fingerprint-sensor.rules
```

Nội dung:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5720", MODE="0666", GROUP="plugdev"
```

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

## 6. Chạy Dashboard

```bash
cd fingerprint_dashboard
cp .env.example .env
# Sửa NEXT_PUBLIC_API_URL nếu orchestrator không chạy local

pnpm install
pnpm dev
```

Dashboard chạy tại: `http://localhost:3000`

---

## 7. Cài Đặt Mosquitto MQTT

### Trên Ubuntu (Host)

```bash
sudo apt update
sudo apt install -y mosquitto mosquitto-clients

# Cho phép kết nối từ bên ngoài (mặc định chỉ local)
sudo nano /etc/mosquitto/conf.d/remote.conf
```

Nội dung file `remote.conf`:

```
listener 1883 0.0.0.0
allow_anonymous true
```

```bash
sudo systemctl restart mosquitto
sudo systemctl enable mosquitto

# Test
mosquitto_sub -h localhost -t "test/#" &
mosquitto_pub -h localhost -t "test/hello" -m "OK"
```

### Trong Docker (tuỳ chọn)

Bỏ comment phần `fingerprint-mqtt` trong `docker-compose.yml` và tạo file `mosquitto.conf`:

```conf
listener 1883
allow_anonymous true
```

```bash
docker compose up -d fingerprint-mqtt
```

---

## Thứ Tự Khởi Động Đề Xuất

```
1. Docker Compose (PostgreSQL + MinIO)
   └── docker compose up -d

2. Mosquitto MQTT Broker
   └── sudo systemctl start mosquitto

3. Orchestrator API
   └── fingerprint-orchestrator-api

4. Dashboard
   └── pnpm dev

5. Worker(s) trên Jetson Nano
   └── fingerprint-worker-api
```
