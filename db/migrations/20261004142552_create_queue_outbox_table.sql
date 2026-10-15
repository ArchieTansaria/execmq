-- migrate:up
CREATE TABLE queue_outbox (
    id UUID PRIMARY KEY,

    job_id UUID NOT NULL,

    queue_name TEXT NOT NULL,

    action TEXT NOT NULL DEFAULT 'ENQUEUE',

    available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    publish_attempts INTEGER NOT NULL DEFAULT 0,

    last_error JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,

    CONSTRAINT queue_outbox_job_fk
        FOREIGN KEY (job_id)
        REFERENCES jobs(id)
        ON DELETE CASCADE,

    CONSTRAINT queue_outbox_action_valid
        CHECK (
            action IN (
                'ENQUEUE'
            )
        ),

    CONSTRAINT queue_outbox_publish_attempts_nonnegative
        CHECK (publish_attempts >= 0)
);


CREATE INDEX idx_queue_outbox_pending
ON queue_outbox (
    available_at,
    created_at,
    id
)
WHERE published_at IS NULL;


CREATE INDEX idx_queue_outbox_job
ON queue_outbox (job_id);

-- migrate:down

