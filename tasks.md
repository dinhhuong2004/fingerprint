# Danh Sách Công Việc (Tasks)

## 1. Hạ Tầng (Infrastructure)

| Task                                                                | Assign | Done |
| ------------------------------------------------------------------- | ------ | ---- |
| Thiết kế Database Schema (PostgreSQL + pgvector)                    |        | [x]  |
| Cấu hình Docker Compose (PostgreSQL, MinIO, MinIO init)             |        | [x]  |
| Cài đặt và cấu hình Mosquitto MQTT Broker                           |        | [x]  |
| Tạo cấu trúc MinIO buckets (fingerprint-models, fingerprint-images) |        | [x]  |
| Seed dữ liệu model mặc định (embedding_v1, matching_v1, pad_v1)     |        | [x]  |

## 2. Big Data & Hệ Thống Log (Kafka, Cassandra, Spark)

| Task                                                              | Assign | Done |
| ----------------------------------------------------------------- | ------ | ---- |
| Cài đặt và cấu hình Apache Kafka làm message buffer               |        | [ ]  |
| Cài đặt và cấu hình Cassandra lưu trữ time-series log             |        | [ ]  |
| Tích hợp Worker gửi log quẹt thẻ (nhẹ) qua MQTT/Backend lên Kafka |        | [ ]  |
| Viết Spark job / Pipeline phân tích dữ liệu log thẻ từ Cassandra  |        | [ ]  |

## 3. Orchestrator (Máy chủ Trung tâm)

| Task                                                             | Assign | Done |
| ---------------------------------------------------------------- | ------ | ---- |
| Khởi tạo project FastAPI + cấu hình uv                           |        | [x]  |
| Kết nối PostgreSQL (asyncpg) + pgvector                          |        | [x]  |
| Kết nối MinIO (presigned upload/download URLs)                   |        | [x]  |
| Kết nối MQTT Broker (aiomqtt)                                    |        | [x]  |
| API quản lý Users (CRUD)                                         |        | [x]  |
| API quản lý Fingerprints (CRUD + embedding vector)               |        | [x]  |
| API quản lý Models (list, upload, deploy)                        |        | [x]  |
| API Health check                                                 |        | [x]  |
| MQTT Handler: Worker heartbeat + trạng thái online/offline       |        | [x]  |
| MQTT Handler: Worker enrollment (nhận dữ liệu đăng ký từ worker) |        | [x]  |
| MQTT Handler: Broadcast enrollment tới các worker khác (sync)    |        | [x]  |
| MQTT Handler: Model update command (đẩy model xuống worker)      |        | [x]  |
| MQTT Handler: Model status tracking                              |        | [x]  |
| MQTT Handler: Presigned URL enrollment upload                    |        | [x]  |
| MQTT Handler: Sync check khi worker reconnect                    |        | [x]  |
| MQTT Handler: Broadcast user/fingerprint deletion                |        | [x]  |
| MQTT Handler: Edge register/verify (external edge devices)       |        | [x]  |
| Logging worker events vào file / Centralized Logs                |        | [x]  |
| CLI interactive giám sát MQTT                                    |        | [x]  |
| Script tự động cài đặt (`setup_orchestrator_env.sh`)             |        | [x]  |

## 4. Worker (Jetson Nano - Tiền tuyến)

| Task                                                           | Assign | Done |
| -------------------------------------------------------------- | ------ | ---- |
| Khởi tạo project tương thích Python 3.6                        |        | [x]  |
| AI Pipeline: TensorRT inference (FP16)                         |        | [x]  |
| AI Pipeline: ONNX Runtime fallback                             |        | [x]  |
| AI Pipeline: Tự động chọn backend (TensorRT > ONNX > Mock)     |        | [x]  |
| AI Pipeline: Convert ONNX → TensorRT engine (trtexec + pycuda) |        | [x]  |
| Tích hợp USB Fingerprint Sensor driver                         |        | [x]  |
| Database: SQLite + aiosqlite                                   |        | [x]  |
| Database: FAISS vector index (KNN search)                      |        | [x]  |
| API: Enrollment (đăng ký vân tay)                              |        | [x]  |
| API: Verification (xác thực 1:1)                               |        | [x]  |
| API: Identification (nhận diện 1:N)                            |        | [x]  |
| API: WebSocket streaming preview                               |        | [x]  |
| API: WebSocket verify/identify realtime                        |        | [x]  |
| MQTT: Kết nối orchestrator                                     |        | [x]  |
| MQTT: Heartbeat định kỳ                                        |        | [x]  |
| MQTT: Nhận lệnh model update + auto download/convert           |        | [x]  |
| MQTT: Gửi enrollment event lên orchestrator                    |        | [x]  |
| MQTT: Nhận sync data từ worker khác                            |        | [x]  |
| MQTT: Nhận sync/check → flush offline data                     |        | [x]  |
| MQTT: Nhận user/fingerprint deletion                           |        | [x]  |
| MQTT: Upload ảnh qua presigned MinIO URL                       |        | [x]  |
| Offline Mode: Hoạt động khi mất mạng                           |        | [x]  |
| Offline Mode: Đánh dấu is_synced = False                       |        | [x]  |
| Offline Mode: Auto sync khi reconnect                          |        | [x]  |
| Kiểm tra trùng lặp vân tay (duplicate enrollment check)        |        | [x]  |
| Mã hoá embedding (Fernet encryption at rest)                   |        | [x]  |
| GUI: PyQt5 giao diện cảm ứng                                   |        | [x]  |
| CLI: Interactive MQTT monitoring                               |        | [x]  |
| Systemd service cho production                                 |        | [x]  |
| Script tự động cài đặt (`setup_jetson_env.sh`)                 |        | [x]  |
| Quốc tế hoá: Dịch toàn bộ code sang tiếng Anh                  |        | [x]  |

## 5. Dashboard (Hậu phương)

| Task                                               | Assign | Done |
| -------------------------------------------------- | ------ | ---- |
| Khởi tạo project Next.js + Tailwind + shadcn       |        | [x]  |
| Trang Dashboard: Tổng quan hệ thống                |        | [x]  |
| Trang Workers: Giám sát fleet + deploy model       |        | [x]  |
| Trang Users: Danh sách người dùng master           |        | [x]  |
| Trang User Detail: Gallery vân tay                 |        | [x]  |
| Trang Fingerprints: Tất cả bản ghi vân tay         |        | [x]  |
| Trang Models: MinIO browser + ma trận model-worker |        | [x]  |
| Trang Logs: Stream sự kiện realtime                |        | [x]  |

## 6. Đánh giá & Kiểm thử (Evaluation & Testing)

| Task                                                                | Assign | Done |
| ------------------------------------------------------------------- | ------ | ---- |
| Test case: Mô phỏng kịch bản đứt cáp mạng (Offline-Sync)            |        | [ ]  |
| Test case: Mô phỏng quá tải (hàng ngàn người quẹt thẻ cùng lúc)     |        | [ ]  |
| Đo lường Throughput và Latency (Thiết kế biểu đồ minh hoạ)          |        | [ ]  |
| Phân tích so sánh: Thời gian xử lý có vs không có TensorRT          |        | [ ]  |
| Phân tích so sánh: Cắm trực tiếp DB vs Kafka làm đệm (Buffer)       |        | [ ]  |
| Phân tích so sánh: Giao thức MQTT vs HTTP trong hệ thống IoT / FEMP |        | [ ]  |

## 7. Tài Liệu Dự Án (Report & Presentation)

| Task                                                     | Assign | Done |
| -------------------------------------------------------- | ------ | ---- |
| README tổng quan hệ thống                                |        | [x]  |
| Workflow diagrams (Mermaid / PNG files)                  |        | [x]  |
| Hướng dẫn vận hành                                       |        | [x]  |
| Danh sách tasks được tracking                            |        | [x]  |
| Demo video / recording hệ thống chạy thực tế             |        | [ ]  |
| Chuẩn bị Slide thuyết trình & Bảo vệ giải pháp kiến trúc |        | [ ]  |
