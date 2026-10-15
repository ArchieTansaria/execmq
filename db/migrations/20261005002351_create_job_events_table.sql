-- migrate:up
CREATE TABLE job_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    job_id UUID NOT NULL,
    attempt_id UUID,

    event_type TEXT NOT NULL,

    from_status TEXT,
    to_status TEXT,

    actor_type TEXT NOT NULL,
    actor_id TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT job_events_job_fk
        FOREIGN KEY (job_id)
        REFERENCES jobs(id)
        ON DELETE CASCADE,

    CONSTRAINT job_events_attempt_fk
        FOREIGN KEY (attempt_id)
        REFERENCES job_attempts(id)
        ON DELETE SET NULL,

    CONSTRAINT job_events_event_type_nonempty
        CHECK (BTRIM(event_type) <> ''),

    CONSTRAINT job_events_actor_type_nonempty
        CHECK (BTRIM(actor_type) <> ''),

    CONSTRAINT job_events_from_status_valid
        CHECK (
            from_status IS NULL
            OR from_status IN (
                'QUEUED',
                'PROCESSING',
                'RETRY_WAIT',
                'COMPLETED',
                'DLQ'
            )
        ),

    CONSTRAINT job_events_to_status_valid
        CHECK (
            to_status IS NULL
            OR to_status IN (
                'QUEUED',
                'PROCESSING',
                'RETRY_WAIT',
                'COMPLETED',
                'DLQ'
            )
        )
);


CREATE INDEX idx_job_events_job_timeline
ON job_events (job_id, id);


CREATE INDEX idx_job_events_attempt_timeline
ON job_events (attempt_id, id)
WHERE attempt_id IS NOT NULL;

-- migrate:down

