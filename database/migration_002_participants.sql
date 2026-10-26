-- =====================================================================
-- Migration 002: Student participants (non-login registry rows)
-- Applies to live smarttrack_db (system_core schema)
-- =====================================================================

BEGIN;

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS participant_type VARCHAR(20)
        NOT NULL DEFAULT 'Faculty';

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS participant_name VARCHAR(150);

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS student_id_no VARCHAR(50);

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS program VARCHAR(150);

ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_participant_type;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_participant_type
    CHECK (participant_type IN ('Faculty', 'Student'));

COMMENT ON COLUMN system_core.travels.participant_type
    IS 'Faculty or Student (students have no login account; rows entered by faculty/admin)';
COMMENT ON COLUMN system_core.travels.participant_name
    IS 'Required for Student participants';
COMMENT ON COLUMN system_core.travels.student_id_no
    IS 'Student ID number (student participants only)';
COMMENT ON COLUMN system_core.travels.program
    IS 'Degree program e.g. BSTM (student participants only)';

COMMIT;
