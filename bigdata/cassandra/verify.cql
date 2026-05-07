USE fingerprint_logs;

CONSISTENCY ONE;

SELECT worker_id, event_day, event_time, event_id, event_type, user_id, result, latency_ms
FROM worker_event_logs_by_day
WHERE worker_id = 'worker-01'
  AND event_day = '2026-05-06'
LIMIT 10;

SELECT worker_id, event_day, event_time, event_type, result, latency_ms
FROM worker_event_logs_by_day
WHERE worker_id = 'worker-03'
  AND event_day = '2026-05-07'
LIMIT 10;
