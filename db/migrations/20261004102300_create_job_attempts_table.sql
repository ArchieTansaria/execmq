-- migrate:up
CREATE TABLE job_attempts (
    id UUID PRIMARY KEY,
    job_id UUID NOT NULL,
    attempt_number INTEGER NOT NULL,
    worker_id TEXT NOT NULL,
    claim_token UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'RUNNING',
    error JSONB,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,

    CONSTRAINT job_attempts_job_fk
        FOREIGN KEY (job_id)
        REFERENCES jobs(id)
        ON DELETE CASCADE,

    CONSTRAINT job_attempts_number_positive
        CHECK (attempt_number > 0),

    CONSTRAINT job_attempts_status_valid
        CHECK (
            status IN (
                'RUNNING',
                'SUCCEEDED',
                'FAILED',
                'STALLED'
            )
        ),

    CONSTRAINT job_attempts_job_attempt_unique
        UNIQUE (job_id, attempt_number),

    CONSTRAINT job_attempts_finished_at_consistent
        CHECK (
            (
                status = 'RUNNING'
                AND finished_at IS NULL
            )
            OR
            (
                status IN ('SUCCEEDED', 'FAILED', 'STALLED')
                AND finished_at IS NOT NULL
            )
        )
);

-- migrate:down

