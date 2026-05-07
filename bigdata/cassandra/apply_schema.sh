#!/usr/bin/env bash
set -euo pipefail

CASSANDRA_HOST="${CASSANDRA_HOST:-fingerprint-cassandra}"
CASSANDRA_PORT="${CASSANDRA_PORT:-9042}"
CASSANDRA_LOG_TTL_SECONDS="${CASSANDRA_LOG_TTL_SECONDS:-7776000}"
SCHEMA_TEMPLATE_PATH="${SCHEMA_TEMPLATE_PATH:-/cassandra/schema.cql.template}"
RENDERED_SCHEMA_PATH="/tmp/fingerprint_logs_schema.cql"

until cqlsh "$CASSANDRA_HOST" "$CASSANDRA_PORT" -e "DESCRIBE KEYSPACES" >/dev/null 2>&1; do
  echo "Waiting for Cassandra at ${CASSANDRA_HOST}:${CASSANDRA_PORT}..."
  sleep 5
done

sed "s/__DEFAULT_TTL__/${CASSANDRA_LOG_TTL_SECONDS}/g" "$SCHEMA_TEMPLATE_PATH" > "$RENDERED_SCHEMA_PATH"
cqlsh "$CASSANDRA_HOST" "$CASSANDRA_PORT" -f "$RENDERED_SCHEMA_PATH"

echo "Schema applied with default TTL=${CASSANDRA_LOG_TTL_SECONDS}s"
