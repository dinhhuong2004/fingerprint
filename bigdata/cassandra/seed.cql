USE fingerprint_logs;

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-01', '2026-05-06', '2026-05-06T08:00:10Z', 11111111-1111-1111-1111-111111111111, 'verify', 'user-1001', 'success', 118, '{"device_id":"dev-01","site":"line-a"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-01', '2026-05-06', '2026-05-06T08:01:33Z', 11111111-1111-1111-1111-111111111112, 'verify', 'user-1002', 'fail', 345, '{"device_id":"dev-01","site":"line-a"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-01', '2026-05-06', '2026-05-06T08:03:02Z', 11111111-1111-1111-1111-111111111113, 'identify', null, 'success', 210, '{"device_id":"dev-01","site":"line-a"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-02', '2026-05-06', '2026-05-06T08:00:42Z', 22222222-2222-2222-2222-222222222221, 'verify', 'user-2001', 'success', 95, '{"device_id":"dev-02","site":"line-b"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-02', '2026-05-06', '2026-05-06T09:10:42Z', 22222222-2222-2222-2222-222222222222, 'identify', null, 'fail', 420, '{"device_id":"dev-02","site":"line-b"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-03', '2026-05-07', '2026-05-07T10:12:11Z', 33333333-3333-3333-3333-333333333331, 'verify', 'user-3001', 'success', 102, '{"device_id":"dev-03","site":"line-c"}');

INSERT INTO worker_event_logs_by_day (worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms, metadata_json)
VALUES ('worker-03', '2026-05-07', '2026-05-07T10:14:18Z', 33333333-3333-3333-3333-333333333332, 'verify', 'user-3002', 'fail', 367, '{"device_id":"dev-03","site":"line-c"}');
