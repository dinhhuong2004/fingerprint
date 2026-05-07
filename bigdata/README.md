# Big Data: Cassandra + Spark Pipeline

Tài liệu này hướng dẫn chạy end-to-end cho 2 task Big Data:

1. Cài đặt Cassandra lưu trữ time-series logs.
2. Chạy Spark job phân tích log từ Cassandra.

## 1) Khởi động hạ tầng

Từ thư mục repo:

```bash
docker compose up -d fingerprint-cassandra fingerprint-cassandra-init fingerprint-spark
```

Hoặc dùng script:

```bash
./bigdata/scripts/start_bigdata_stack.sh
```

## 2) Init schema Cassandra

Schema được auto-apply bởi service `fingerprint-cassandra-init` sau khi Cassandra healthy.

Nếu cần apply lại thủ công:

```bash
./bigdata/scripts/apply_cassandra_schema.sh
```

### Schema time-series

- Keyspace: `fingerprint_logs`
- Table: `worker_event_logs_by_day`
- Partition key: `(worker_id, event_day)`
- Clustering: `event_time DESC, event_id ASC`
- Cột chính:
  - `event_id`
  - `event_time`
  - `event_type`
  - `worker_id`
  - `user_id` (nullable)
  - `result` (`success`/`fail`)
  - `latency_ms`
  - `metadata_json`
  - `event_day` (filter theo ngày)

TTL mặc định configurable qua biến môi trường `CASSANDRA_LOG_TTL_SECONDS` (default: `7776000`, tương đương 90 ngày).

## 3) Seed dữ liệu mẫu

```bash
./bigdata/scripts/seed_cassandra_logs.sh
```

## 4) Query verify Cassandra

```bash
./bigdata/scripts/verify_cassandra_logs.sh
```

## 5) Chạy Spark job phân tích log

### Batch theo ngày

```bash
./bigdata/spark/run_spark_job.sh --day 2026-05-06
```

### Batch theo khoảng thời gian

```bash
./bigdata/spark/run_spark_job.sh --from 2026-05-06T08:00:00 --to 2026-05-06T10:00:00
```

Spark job đọc Cassandra bằng Spark Cassandra Connector và sinh các metrics:

- Tổng events theo phút (`events_per_minute`)
- Tổng events theo giờ (`events_per_hour`)
- Tỉ lệ success/fail theo `event_type` (`success_fail_by_event_type`)
- Latency p50/p95/p99 theo giờ (`latency_percentiles`)
- Top workers theo số events (`top_workers`)

## 6) Kiểm tra output

Kết quả Parquet được ghi local vào thư mục `outputs/` tại repo:

```bash
find outputs -maxdepth 4 -type d | sort
```

Ví dụ path:

- `outputs/day=2026-05-06/events_per_minute/`
- `outputs/day=2026-05-06/events_per_hour/`
- `outputs/day=2026-05-06/success_fail_by_event_type/`
- `outputs/day=2026-05-06/latency_percentiles/`
- `outputs/day=2026-05-06/top_workers/`

## Troubleshooting nhanh

1. **Cassandra chưa ready**
   - Chờ `fingerprint-cassandra` healthy rồi chạy lại script.
   - Kiểm tra log: `docker compose logs --tail=100 fingerprint-cassandra`

2. **Schema chưa được apply tự động**
   - Kiểm tra init container: `docker compose logs --tail=100 fingerprint-cassandra-init`
   - Re-apply thủ công: `./bigdata/scripts/apply_cassandra_schema.sh`

3. **Spark không tải được Cassandra connector**
   - Kiểm tra internet/proxy từ môi trường chạy container.
   - Chạy lại `run_spark_job.sh` để Spark tải package lại.

4. **Sai host/port Cassandra**
   - Trong Spark job, mặc định host là `fingerprint-cassandra`, port `9042`.
   - Có thể override qua tham số `--cassandra-host`, `--cassandra-port`.

5. **Lỗi query do partition key**
   - Bảng được thiết kế theo partition `(worker_id, event_day)`, nên query Cassandra trực tiếp cần chỉ rõ partition key.
   - Spark đọc batch toàn bảng thì vẫn chạy được nhưng sẽ scan dữ liệu nhiều hơn nếu không lọc thời gian.
