#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"
docker compose exec -T fingerprint-cassandra /bin/bash -lc "CASSANDRA_HOST=127.0.0.1 CASSANDRA_PORT=9042 CASSANDRA_LOG_TTL_SECONDS='${CASSANDRA_LOG_TTL_SECONDS:-7776000}' SCHEMA_TEMPLATE_PATH=/cassandra/schema.cql.template /cassandra/apply_schema.sh"

echo "Schema re-applied successfully."
