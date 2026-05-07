#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"
docker compose up -d fingerprint-cassandra fingerprint-cassandra-init fingerprint-spark

echo "Big Data services started (Cassandra + Cassandra init + Spark)."
