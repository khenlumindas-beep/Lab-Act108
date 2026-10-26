-- Migration 008: Phase 2 — Database Design
-- Finalizes the ERD per the design doc (§12.1 entities, §17 remark/audit structure).
-- Adds the 7 missing entities, reconciles schema drift, and adds supporting indexes.
-- All statements are idempotent so the script can be safely re-run.

-- ============================================================
-- 1. DRIFT FIXES (live DB differs from models.py)
-- ============================================================

-- departments: unique_dept_per_college exists in models.py but not in the live DB.
-- Deduplicate first so the constraint cannot fail on existing data.
DELETE FROM system_core.departments d
USING system_core.departments keep
WHERE d.department_id > keep.department_id
  AND d.college_id = keep.college_id
  AND COALESCE(d.code, '') = COALESCE(keep.code, '');

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'unique_dept_per_college'
    ) THEN
        ALTER TABLE system_core.departments
            ADD CONSTRAINT unique_dept_per_college UNIQUE (college_id, code);
    END IF;
END $$;

-- users.role: enforce the two real roles at the DB level (was manual SQL only).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check'
    ) THEN
        ALTER TABLE system_core.users
            ADD CONSTRAINT users_role_check CHECK (role IN ('super_admin', 'faculty'));
    END IF;
END $$;

-- ============================================================
-- 2. REFERENCE TABLES
-- ============================================================

-- Authoritative travel workflow states (design doc §8.1, 8 values).
CREATE TABLE IF NOT EXISTS system_core.ref_travel_statuses (
    code        VARCHAR(30) PRIMARY KEY,
    label       VARCHAR(50) NOT NULL,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_terminal BOOLEAN NOT NULL DEFAULT FALSE
);
INSERT INTO system_core.ref_travel_statuses (code, label, sort_order, is_terminal) VALUES
    ('Draft',         'Draft',          1, FALSE),
    ('Submitted',     'Submitted',      2, FALSE),
    ('Under Review',  'Under Review',   3, FALSE),
    ('Incomplete',    'Incomplete',     4, FALSE),
    ('Approved',      'Approved',       5, FALSE),
    ('Ongoing',       'Ongoing',        6, FALSE),
    ('Completed',     'Completed',      7, TRUE),
    ('Cancelled',     'Cancelled',      8, TRUE)
ON CONFLICT (code) DO NOTHING;

-- Allowed workflow transitions (source -> target). Mirrors constants.py.
CREATE TABLE IF NOT EXISTS system_core.ref_workflow_transitions (
    transition_id SERIAL PRIMARY KEY,
    from_status   VARCHAR(30) NOT NULL REFERENCES system_core.ref_travel_statuses(code),
    to_status     VARCHAR(30) NOT NULL REFERENCES system_core.ref_travel_statuses(code),
    UNIQUE (from_status, to_status)
);
INSERT INTO system_core.ref_workflow_transitions (from_status, to_status) VALUES
    ('Draft',        'Submitted'),
    ('Draft',        'Cancelled'),
    ('Submitted',    'Under Review'),
    ('Submitted',    'Cancelled'),
    ('Under Review', 'Incomplete'),
    ('Under Review', 'Approved'),
    ('Under Review', 'Cancelled'),
    ('Incomplete',   'Submitted'),
    ('Incomplete',   'Cancelled'),
    ('Approved',     'Ongoing'),
    ('Approved',     'Cancelled'),
    ('Ongoing',      'Completed'),
    ('Ongoing',      'Cancelled')
ON CONFLICT (from_status, to_status) DO NOTHING;

-- Document verification lifecycle (design doc §8.1, 6 values).
CREATE TABLE IF NOT EXISTS system_core.ref_document_statuses (
    code       VARCHAR(30) PRIMARY KEY,
    label      VARCHAR(50) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0
);
INSERT INTO system_core.ref_document_statuses (code, label, sort_order) VALUES
    ('Not Uploaded',         'Not Uploaded',         1),
    ('Submitted',            'Submitted',            2),
    ('Under Verification',   'Under Verification',   3),
    ('Verified',             'Verified',             4),
    ('Rejected',             'Rejected',             5),
    ('Resubmission Required','Resubmission Required',6)
ON CONFLICT (code) DO NOTHING;

-- Re-entry activity status (design doc §8.1, 5 values).
CREATE TABLE IF NOT EXISTS system_core.ref_reentry_statuses (
    code       VARCHAR(30) PRIMARY KEY,
    label      VARCHAR(50) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0
);
INSERT INTO system_core.ref_reentry_statuses (code, label, sort_order) VALUES
    ('Not Started',      'Not Started',      1),
    ('For Implementation','For Implementation',2),
    ('Ongoing',          'Ongoing',          3),
    ('Completed',        'Completed',        4),
    ('Not Complied',     'Not Complied',     5)
ON CONFLICT (code) DO NOTHING;

-- Compliance status (design doc §8.1, 3 values) + Appendix A colour legend.
CREATE TABLE IF NOT EXISTS system_core.ref_compliance_statuses (
    code       VARCHAR(30) PRIMARY KEY,
    label      VARCHAR(50) NOT NULL,
    colour     VARCHAR(20),
    sort_order INTEGER NOT NULL DEFAULT 0
);
INSERT INTO system_core.ref_compliance_statuses (code, label, colour, sort_order) VALUES
    ('Fully Compliant',    'Fully Compliant',    'Green',  1),
    ('Partially Compliant','Partially Compliant','Yellow', 2),
    ('Needs Action',       'Needs Action',       'Red',    3)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 3. CORE CASE TABLES
-- ============================================================

-- post_travel_requirements: per-travel checklist of post-travel deliverables.
CREATE TABLE IF NOT EXISTS system_core.post_travel_requirements (
    requirement_id SERIAL PRIMARY KEY,
    travel_id      INTEGER NOT NULL REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    doc_type_id    INTEGER REFERENCES system_core.document_types(doc_type_id),
    requirement    VARCHAR(150) NOT NULL,
    status         VARCHAR(30) NOT NULL DEFAULT 'Not Submitted',
    due_date       DATE,
    completed_at   TIMESTAMP WITHOUT TIME ZONE,
    remarks        TEXT,
    created_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_post_travel_req_status CHECK (
        status IN ('Not Submitted','Submitted','Verified','Incomplete','Waived')
    )
);
CREATE INDEX IF NOT EXISTS idx_post_travel_req_travel
    ON system_core.post_travel_requirements (travel_id);

-- reentry_activities: knowledge-sharing / re-entry plan per travel.
CREATE TABLE IF NOT EXISTS system_core.reentry_activities (
    activity_id   SERIAL PRIMARY KEY,
    travel_id     INTEGER NOT NULL REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    activity      VARCHAR(255) NOT NULL,
    description   TEXT,
    target_date   DATE,
    status        VARCHAR(30) NOT NULL DEFAULT 'Not Started',
    evidence_path VARCHAR(500),
    completed_at  TIMESTAMP WITHOUT TIME ZONE,
    remarks       TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_reentry_status CHECK (
        status IN ('Not Started','For Implementation','Ongoing','Completed','Not Complied')
    )
);
CREATE INDEX IF NOT EXISTS idx_reentry_travel
    ON system_core.reentry_activities (travel_id);
CREATE INDEX IF NOT EXISTS idx_reentry_status
    ON system_core.reentry_activities (status);

-- compliance_records: calculated compliance state (BR-07). One row per travel,
-- recomputed from actual document/activity statuses — never hand-toggled.
CREATE TABLE IF NOT EXISTS system_core.compliance_records (
    compliance_id      SERIAL PRIMARY KEY,
    travel_id          INTEGER NOT NULL UNIQUE REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    status             VARCHAR(30) NOT NULL DEFAULT 'Needs Action',
    score              NUMERIC(5,2) NOT NULL DEFAULT 0,
    pre_travel_ok      BOOLEAN NOT NULL DEFAULT FALSE,
    post_travel_ok     BOOLEAN NOT NULL DEFAULT FALSE,
    reentry_ok         BOOLEAN NOT NULL DEFAULT FALSE,
    required_docs      INTEGER NOT NULL DEFAULT 0,
    verified_docs      INTEGER NOT NULL DEFAULT 0,
    priority           VARCHAR(10) NOT NULL DEFAULT 'medium',
    computed_at        TIMESTAMP WITHOUT TIME ZONE,
    created_at         TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_compliance_status CHECK (
        status IN ('Fully Compliant','Partially Compliant','Needs Action')
    ),
    CONSTRAINT chk_compliance_priority CHECK (priority IN ('low','medium','high'))
);
CREATE INDEX IF NOT EXISTS idx_compliance_status
    ON system_core.compliance_records (status);
CREATE INDEX IF NOT EXISTS idx_compliance_priority
    ON system_core.compliance_records (priority);

-- ============================================================
-- 4. AUDIT STRUCTURE
-- ============================================================

-- remark_history: structured compliance notes (BR-12) + status-transition trail.
-- Reproduces the doc's example sequence (p.24): uploaded -> under verification ->
-- rejected -> resubmitted -> verified.
CREATE TABLE IF NOT EXISTS system_core.remark_history (
    remark_id        SERIAL PRIMARY KEY,
    travel_id        INTEGER REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    document_id      INTEGER REFERENCES system_core.documents(document_id) ON DELETE SET NULL,
    admin_id         INTEGER REFERENCES system_core.users(user_id),
    remark_type      VARCHAR(50),
    action           VARCHAR(50),
    affected_requirement VARCHAR(100),
    remark_text      TEXT,
    previous_status  VARCHAR(30),
    new_status       VARCHAR(30),
    created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_remark_type CHECK (
        remark_type IS NULL OR remark_type IN (
            'Missing Document','Incorrect Document','Expired','Illegible',
            'Missing Signature','Wrong Document Type','Post-Travel Pending',
            'Re-entry Overdue','General'
        )
    ),
    CONSTRAINT chk_remark_action CHECK (
        action IS NULL OR action IN (
            'For Verification','For Resubmission','Follow Up','Approved',
            'Rejected','No Further Action','General'
        )
    )
);
CREATE INDEX IF NOT EXISTS idx_remark_history_travel
    ON system_core.remark_history (travel_id);
CREATE INDEX IF NOT EXISTS idx_remark_history_document
    ON system_core.remark_history (document_id);
CREATE INDEX IF NOT EXISTS idx_remark_history_admin
    ON system_core.remark_history (admin_id);

-- audit_logs: security + administrative activity history (BR-10, FR-A15).
CREATE TABLE IF NOT EXISTS system_core.audit_logs (
    audit_id      SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES system_core.users(user_id),
    entity_type   VARCHAR(50) NOT NULL,
    entity_id     INTEGER,
    action        VARCHAR(50) NOT NULL,
    description   TEXT,
    ip_address    VARCHAR(45),
    user_agent    VARCHAR(255),
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_audit_entity CHECK (
        entity_type IN ('user','travel','document','compliance','reentry',
                        'post_travel','notification','announcement','system')
    ),
    CONSTRAINT chk_audit_action CHECK (
        action IN ('create','update','delete','login','logout','verify','reject',
                   'resubmit','approve','return','status_change','deactivate',
                   'reactivate','export','other')
    )
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user
    ON system_core.audit_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
    ON system_core.audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created
    ON system_core.audit_logs (created_at);

-- ============================================================
-- 5. AI STAGING TABLES (Phase 7/8 target; created now for schema completeness)
-- ============================================================

CREATE TABLE IF NOT EXISTS system_core.ai_document_analysis (
    analysis_id       SERIAL PRIMARY KEY,
    document_id       INTEGER NOT NULL REFERENCES system_core.documents(document_id) ON DELETE CASCADE,
    suggested_type    VARCHAR(100),
    confidence        NUMERIC(5,4),
    extracted_text    TEXT,
    issues            TEXT,
    issue_flags       TEXT,
    status            VARCHAR(30) NOT NULL DEFAULT 'pending',
    created_at        TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ai_analysis_status CHECK (
        status IN ('pending','complete','failed','skipped')
    )
);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_document
    ON system_core.ai_document_analysis (document_id);

CREATE TABLE IF NOT EXISTS system_core.ai_compliance_insights (
    insight_id      SERIAL PRIMARY KEY,
    travel_id       INTEGER REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    insight_type    VARCHAR(50),
    summary         TEXT,
    priority        VARCHAR(10),
    suggested_remark TEXT,
    is_accepted     BOOLEAN,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ai_insight_priority CHECK (
        priority IS NULL OR priority IN ('low','medium','high')
    )
);
CREATE INDEX IF NOT EXISTS idx_ai_insights_travel
    ON system_core.ai_compliance_insights (travel_id);
