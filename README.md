# Hệ Thống Nhận Diện Vân Tay — Tổng Quan

## Giới thiệu

Hệ thống nhận diện vân tay phân tán (Distributed Fingerprint Recognition System) sử dụng kiến trúc **Master – Worker** để triển khai nhận diện sinh trắc học trên các thiết bị biên (Jetson Nano). Hệ thống cho phép đăng ký, xác thực vân tay tại thiết bị biên với thời gian phản hồi dưới 200ms, đồng bộ dữ liệu liên tục về máy chủ trung tâm, và hỗ trợ hoạt động **offline** khi mất mạng.

---

## Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR (Server)                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │  FastAPI      │  │  PostgreSQL  │  │    MinIO      │  │  Mosquitto │  │
│  │  REST API     │  │  + pgvector  │  │  (S3 Storage) │  │  (MQTT)    │  │
│  │  Port: 8001   │  │  Port: 5433  │  │  Port: 9000   │  │  Port:1883 │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘  │
│         └──────────────────┴────────────────┴────────────────┘          │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │           Dashboard (Next.js) — Port: 3000                   │       │
│  │           Giám sát, quản lý workers, users, models           │       │
│  └──────────────────────────────────────────────────────────────┘       │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ MQTT (pub/sub)
          ┌──────────────────┼──────────────────┐
          │                  │                  │
   ┌──────┴──────┐   ┌──────┴──────┐   ┌──────┴──────┐
   │  Worker 1   │   │  Worker 2   │   │  Worker N   │
   │  Jetson Nano│   │  Jetson Nano│   │  Jetson Nano│
   │  Python 3.6 │   │  Python 3.6 │   │  Python 3.6 │
   │  TensorRT   │   │  TensorRT   │   │  TensorRT   │
   │  SQLite     │   │  SQLite     │   │  SQLite     │
   │  FAISS      │   │  FAISS      │   │  FAISS      │
   │  USB Sensor │   │  USB Sensor │   │  USB Sensor │
   └─────────────┘   └─────────────┘   └─────────────┘
```

---

## Các Repository

| Repository                   | Mô tả                                                  | Link                                                                   |
| ---------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| **fingerprint_orchestrator** | Server trung tâm — FastAPI + MQTT + PostgreSQL + MinIO | [GitHub](https://github.com/Puda14/fingerprint_orchestrator/tree/main) |
| **fingerprint-jetson-nano**  | Worker trên Jetson Nano — AI inference + cảm biến USB  | [GitHub](https://github.com/Puda14/fingerprint-jetson-nano/tree/main)  |
| **fingerprint_dashboard**    | Web dashboard giám sát và quản lý hệ thống             | [GitHub](https://github.com/Puda14/fingerprint_dashboard)              |
| **fingerprint-bigdata**      | Tài liệu dự án (repo hiện tại)                         | —                                                                      |

---

## Các Thành Phần Chính

### 1. Orchestrator (Máy Chủ Trung Tâm)

Đóng vai trò **Master** trong kiến trúc Master-Worker.

- **Framework**: FastAPI (Python ≥ 3.10)
- **Giao tiếp**: MQTT qua Mosquitto broker
- **API Port**: `8001`
- **Chức năng**:
  - Quản lý danh sách worker (heartbeat, trạng thái online/offline)
  - Lưu trữ dữ liệu vân tay master (PostgreSQL + pgvector)
  - Quản lý model AI (upload/download qua MinIO)
  - Đẩy lệnh xuống worker (cập nhật model, sync dữ liệu, task embed/verify)
  - Broadcast dữ liệu đăng ký mới tới tất cả worker
  - Xử lý đồng bộ offline khi worker reconnect

### 2. Worker (Thiết Bị Biên — Jetson Nano)

Mỗi worker là một **Jetson Nano** chạy inference AI tại chỗ (edge AI).

- **Framework**: FastAPI (Python 3.6 — giới hạn bởi JetPack)
- **Inference**: TensorRT (FP16) hoặc ONNX Runtime (fallback)
- **Database cục bộ**: SQLite + FAISS (vector search)
- **Cảm biến**: USB Fingerprint Sensor (VID: `0x0483`, PID: `0x5720`)
- **Chức năng**:
  - Quét, capture ảnh vân tay từ sensor USB
  - Rút trích embedding vector 256 chiều qua TensorRT
  - Đăng ký người dùng mới (lưu local + đồng bộ lên orchestrator)
  - Xác thực 1:N bằng FAISS KNN (cosine similarity)
  - Streaming preview real-time qua WebSocket
  - Hoạt động offline, sync khi có mạng
  - Tự động tải và convert model ONNX → TensorRT engine

### 3. Dashboard (Giao Diện Web)

Giao diện quản trị cho quản lý viên.

- **Framework**: Next.js 16 + React 19 + Tailwind CSS + shadcn/ui
- **Port**: `3000`
- **Kết nối**: Orchestrator REST API (`/api/*`)
- **Các trang**:
  - `/dashboard` — Tổng quan hệ thống
  - `/workers` — Giám sát fleet worker, deploy model
  - `/users` — Danh sách người dùng master
  - `/users/[id]` — Gallery vân tay của từng user
  - `/fingerprints` — Tất cả bản ghi vân tay
  - `/models` — Duyệt model trên MinIO + ma trận model-worker
  - `/logs` — Stream sự kiện worker real-time

### 4. Hạ Tầng (Infrastructure)

Chạy dưới dạng Docker Compose tại máy orchestrator.

#### PostgreSQL + pgvector

- **Image**: `pgvector/pgvector:pg16`
- **Port**: `5433` (map ra host)
- **Vai trò**: Master database — lưu trữ users, fingerprints (embedding vector 256D), models, worker_models
- **Extension**: `vector` cho tìm kiếm vector similarity

#### MinIO (S3 Object Storage)

- **Image**: `minio/minio:latest`
- **Port API**: `9000`, **Console**: `9001`
- **Buckets**:
  - `fingerprint-models/` — Chứa model ONNX theo cấu trúc: `{type}/{name}_v{version}/model.onnx`
    - `embedding/` — Model rút trích đặc trưng
    - `matching/` — Model so khớp
    - `pad/` — Model phát hiện giả mạo (Presentation Attack Detection)
  - `fingerprint-images/` — Data lake chứa ảnh vân tay

#### Mosquitto (MQTT Broker)

- **Port**: `1883`
- **Vai trò**: Kênh giao tiếp pub/sub giữa orchestrator và các worker
- **Topics chính**: `worker/+/heartbeat`, `worker/+/status`, `task/{worker_id}/*`

#### SQLite (Tại Worker)

- **Vai trò**: Database cục bộ của từng Jetson Nano
- **Lưu trữ**: Users, fingerprints, trạng thái sync (`is_synced`)
- **Ưu điểm**: Hoạt động offline, không cần kết nối server

---

## Cơ Sở Dữ Liệu Master (PostgreSQL)

| Bảng            | Mô tả                                                    |
| --------------- | -------------------------------------------------------- |
| `models`        | Quản lý phiên bản model AI (embedding, matching, pad)    |
| `users`         | Thông tin người dùng (user_id, name, metadata JSONB)     |
| `fingerprints`  | Embedding vector 256D, liên kết user, loại ngón tay, ảnh |
| `worker_models` | Theo dõi model nào đã deploy cho worker nào              |

---

## Giao Tiếp MQTT

### Topics Worker → Orchestrator (Publish)

| Topic                                  | Mô tả                                |
| -------------------------------------- | ------------------------------------ |
| `worker/{id}/heartbeat`                | Nhịp tim, thông báo worker còn sống  |
| `worker/{id}/status`                   | Thông tin thiết bị khi kết nối       |
| `worker/{id}/enrolled`                 | Gửi dữ liệu đăng ký vân tay mới      |
| `worker/{id}/model/status`             | Báo cáo trạng thái tải/convert model |
| `worker/{id}/enrollment/upload/status` | Trạng thái upload ảnh lên MinIO      |

### Topics Orchestrator → Worker (Publish)

| Topic                         | Mô tả                                       |
| ----------------------------- | ------------------------------------------- |
| `task/{id}/model/update`      | Lệnh tải model mới                          |
| `task/{id}/sync`              | Broadcast dữ liệu đăng ký tới worker khác   |
| `task/{id}/sync/check`        | Yêu cầu flush dữ liệu offline pending       |
| `task/{id}/enrollment/upload` | Yêu cầu worker upload ảnh qua presigned URL |
| `task/{id}/embed`             | Lệnh rút trích embedding                    |

---

## Tài Liệu Khác

| File                           | Nội dung                                |
| ------------------------------ | --------------------------------------- |
| [bigdata/README.md](./bigdata/README.md) | Hướng dẫn Cassandra + Spark pipeline      |
| [work_flow.md](./work_flow.md) | Workflow diagrams — các luồng hoạt động |
| [operation.md](./operation.md) | Hướng dẫn vận hành, cài đặt, cấu hình   |
| [tasks.md](./tasks.md)         | Danh sách công việc đã thực hiện        |
| [demo.md](./demo.md)           | Link demo                               |
