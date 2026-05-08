# Schema Logs

## 1. ActivityLog (Nhật ký Hoạt động)

Lưu trữ các thao tác chung của hệ thống (ví dụ: thêm/sửa/xóa người dùng, vân tay mới, thiết bị online/offline). Bảng được thiết kế theo cơ chế **offline-first** với cờ `is_synced` để đồng bộ dần lên server khi có mạng.

| Trường dữ liệu | Kiểu dữ liệu (Python) | Mặc định | Ý nghĩa |
|---|---|---|---|
| `id` | `int` (tự tăng) | `None` | Khóa chính của bảng |
| `action_type` | `str` | `"ENTRY"` | Loại hoạt động (ví dụ: `"ENTRY"`, `"EXIT"`, `"REGISTER"`) |
| `user_id` | `str` | `None` | Mã ID người dùng (nếu hành động gắn với một user cụ thể) |
| `details` | `str` | `""` | Chuỗi JSON hoặc text mô tả chi tiết thao tác |
| `timestamp` | `str` (ISO 8601) | `utcnow()` | Thời gian xảy ra sự kiện (UTC) |
| `is_synced` | `bool` | `False` | Trạng thái đồng bộ: đã gửi thành công lên Orchestrator/Kafka chưa? |

## 2. VerificationLog (Nhật ký Quét Vân Tay)

Lưu lại lịch sử của mọi lần đặt tay lên máy quét (dùng cho điểm danh, mở cửa hoặc kiểm toán mức độ chính xác của AI).

| Trường dữ liệu | Kiểu dữ liệu (Python) | Mặc định | Ý nghĩa |
|---|---|---|---|
| `id` | `int` (tự tăng) | `None` | Khóa chính của bảng |
| `matched_user_id` | `int` | `None` | ID người dùng khớp thành công (nếu có) |
| `matched_fp_id` | `int` | `None` | ID của vân tay khớp thành công trong database |
| `mode` | `str` | `"verify"` | Chế độ quét: `"verify"` (1:1) hoặc `"identify"` (1:N) |
| `score` | `float` | `0.0` | Điểm tin cậy (Cosine Similarity Score) |
| `decision` | `str` | `"REJECT"` | Kết quả: `"ACCEPT"`, `"REJECT"`, `"UNCERTAIN"` |
| `latency_ms` | `float` | `0.0` | Độ trễ xử lý AI (tính bằng mili giây) |
| `device_id` | `str` | `""` | Mã thiết bị Jetson/Worker (`WORKER_DEVICE_ID`) |
| `timestamp` | `str` (ISO 8601) | `utcnow()` | Thời gian quét (UTC) |
| `probe_quality` | `float` | `0.0` | Điểm chất lượng ảnh vân tay từ cảm biến |

### Ghi chú mapping ID

- `ActivityLog.user_id` dùng kiểu `str` để lưu **mã nghiệp vụ** (business user code, ví dụ `EMP001`).
- `VerificationLog.matched_user_id` dùng kiểu `int` để lưu **khóa nội bộ** (primary key số nguyên) của bản ghi user đã match.
- `VerificationLog.matched_fp_id` tham chiếu tới khóa chính bản ghi fingerprint trong bảng dữ liệu vân tay (ví dụ bảng `fingerprints`).
