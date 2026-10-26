-- Migration 007: Document Types master list (admin-managed required travel documents)
-- Replaces the static reference list in the admin Document Types section with real CRUD.

CREATE TABLE IF NOT EXISTS system_core.document_types (
    doc_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(20) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_doc_type_category CHECK (category IN ('Pre-Travel', 'Post-Travel'))
);

-- Seed with the current reference list from the admin UI
INSERT INTO system_core.document_types (name, category, is_required, sort_order) VALUES
    ('Travel Authority', 'Pre-Travel', TRUE, 1),
    ('Travel Order', 'Pre-Travel', TRUE, 2),
    ('Passport', 'Pre-Travel', TRUE, 3),
    ('Visa', 'Pre-Travel', FALSE, 4),
    ('Insurance', 'Pre-Travel', TRUE, 5),
    ('Invitation Letter', 'Pre-Travel', TRUE, 6),
    ('Travel Report', 'Post-Travel', TRUE, 7),
    ('Other post-travel documents as required', 'Post-Travel', FALSE, 8)
ON CONFLICT (name) DO NOTHING;
