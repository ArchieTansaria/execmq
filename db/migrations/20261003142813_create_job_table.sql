-- migrate:up

CREATE TABLE jobs (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    queue_name TEXT NOT NULL DEFAULT 'default',
    type TEXT NOT NULL,
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'QUEUED',
    attempts_started INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 3,
    idempotency_key TEXT,
    idempotency_fingerprint TEXT,
    worker_id TEXT,
    claim_token UUID,
    lease_expires_at TIMESTAMPTZ,
    next_retry_at TIMESTAMPTZ,
    result JSONB,
    last_error JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    first_started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    CONSTRAINT jobs_status_valid CHECK (
        status IN (
            'QUEUED',
            'PROCESSING',
            'RETRY_WAIT',
            'COMPLETED',
            'DLQ'
        )
    ),

    CONSTRAINT jobs_attempts_started_nonnegative
        CHECK (attempts_started >= 0),

    CONSTRAINT jobs_max_attempts_positive
        CHECK (max_attempts > 0),

    CONSTRAINT idempotency_key_unique
        UNIQUE (idempotency_key)
);

--PARTIAL INDEXING
-- Find expired processing jobs efficiently.
-- Used by the stalled-job reclaimer.
CREATE INDEX idx_jobs_expired_leases
ON jobs (lease_expires_at, id)
WHERE status = 'PROCESSING'
    AND lease_expires_at IS NOT NULL;


-- Find retries that are due.
CREATE INDEX idx_jobs_due_retries
ON jobs (next_retry_at, id)
WHERE status = 'RETRY_WAIT'
    AND next_retry_at IS NOT NULL;


-- Useful for reconciliation/recovery of queued jobs.
CREATE INDEX idx_jobs_queued
ON jobs (created_at, id)
WHERE status = 'QUEUED';

-- migrate:down
DROP INDEX IF EXISTS idx_jobs_expired_leases;
DROP INDEX IF EXISTS idx_jobs_due_retries; 
DROP INDEX IF EXISTS idx_jobs_queued; 
DROP TABLE IF EXISTS jobs;
