-- ============================================================
-- Fingerprint Recognition System — Database Schema
-- PostgreSQL + pgvector
-- ============================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Models: AI model versioning ─────────────────────────────
CREATE TABLE IF NOT EXISTS models (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    version         VARCHAR(50)  NOT NULL,
    type            VARCHAR(50)  NOT NULL CHECK (type IN ('embedding', 'matching', 'pad')),
    s3_path         VARCHAR(500) NOT NULL,
    description     TEXT DEFAULT '',
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(name, version)
);

-- ── Users ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    user_id         VARCHAR(255) UNIQUE NOT NULL,
    name            VARCHAR(255) NOT NULL,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ── Fingerprints: embedding vectors ─────────────────────────
CREATE TABLE IF NOT EXISTS fingerprints (
    id              SERIAL PRIMARY KEY,
    fingerprint_id  VARCHAR(255) UNIQUE NOT NULL,
    user_id         VARCHAR(255) REFERENCES users(user_id) ON DELETE CASCADE,
    finger_type     VARCHAR(50)  NOT NULL,
    image_path      VARCHAR(500) DEFAULT '',
    embedding       vector(256),
    model_version   VARCHAR(50)  DEFAULT '',
    quality_score   FLOAT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ── Worker Models: track which model each worker uses ───────
CREATE TABLE IF NOT EXISTS worker_models (
    id              SERIAL PRIMARY KEY,
    worker_id       VARCHAR(255) NOT NULL,
    model_id        INTEGER REFERENCES models(id) ON DELETE CASCADE,
    status          VARCHAR(50) DEFAULT 'deployed'
                        CHECK (status IN ('deployed', 'downloading', 'failed')),
    deployed_at     TIMESTAMP DEFAULT NOW()
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_fingerprints_user
    ON fingerprints (user_id);

CREATE INDEX IF NOT EXISTS idx_fingerprints_finger
    ON fingerprints (user_id, finger_type);

CREATE INDEX IF NOT EXISTS idx_worker_models_worker
    ON worker_models (worker_id);

-- ── Seed: default models ────────────────────────────────────
-- Path convention: {type}/{name}_v{version}/model.onnx
INSERT INTO models (name, version, type, s3_path, description)
VALUES
    ('embedding', 'v1', 'embedding', 'embedding/embedding_v1/model.onnx',
     'Default fingerprint embedding extractor'),
    ('matching', 'v1', 'matching', 'matching/matching_v1/model.onnx',
     'Default fingerprint matching model'),
    ('pad', 'v1', 'pad', 'pad/pad_v1/model.onnx',
     'Presentation Attack Detection model')
ON CONFLICT (name, version) DO NOTHING;
