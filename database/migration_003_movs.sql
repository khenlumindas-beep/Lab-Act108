-- =====================================================================
-- Migration 003: MOVs + Pre-Travel / Post-Travel document status
-- Applies to live smarttrack_db (system_core schema)
-- =====================================================================

BEGIN;

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS movs TEXT;

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS pre_travel_status VARCHAR(50);

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS post_travel_status VARCHAR(50);

ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_pre_travel_status;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_pre_travel_status
    CHECK (pre_travel_status IS NULL OR pre_travel_status IN (
        'Not Requested', 'Requested', 'Ongoing',
        'Complete Documents', 'Incomplete Documents', 'No Submission'
    ));

ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_post_travel_status;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_post_travel_status
    CHECK (post_travel_status IS NULL OR post_travel_status IN (
        'Not Submitted', 'Submitted Travel Report',
        'Incomplete Documents', 'Ongoing'
    ));

COMMENT ON COLUMN system_core.travels.movs
    IS 'Means of Verification (workbook MOVs column)';
COMMENT ON COLUMN system_core.travels.pre_travel_status
    IS 'Workbook Pre-Travel Documents status';
COMMENT ON COLUMN system_core.travels.post_travel_status
    IS 'Workbook Post-Travel Documents status';

COMMIT;
