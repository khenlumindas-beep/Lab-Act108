-- =====================================================================
-- Migration 001: Type of Mobility alignment (Workbook Tasks 1, 4, 7)
-- Applies to live smarttrack_db (system_core schema)
-- =====================================================================

BEGIN;

-- Task 1: Rename "activity_type" -> "mobility_type"
ALTER TABLE system_core.travels
    RENAME COLUMN activity_type TO mobility_type;

-- Map legacy activity values to the 11 official Type of Mobility values
UPDATE system_core.travels
SET mobility_type = CASE
    WHEN mobility_type IN ('Conference', 'Forum', 'Annual Meeting', 'Seminar')
        THEN 'International Conference'
    WHEN mobility_type IN ('Workshop', 'Training', 'Summer School')
        THEN 'International Training'
    WHEN mobility_type = 'Research'
        THEN 'Research Mobility'
    WHEN mobility_type IN ('Exchange', 'Faculty Exchange')
        THEN 'Faculty Exchange'
    WHEN mobility_type = 'Fellowship'
        THEN 'Fellowship'
    ELSE mobility_type
END;

-- Any remaining non-conforming value becomes 'Other'
UPDATE system_core.travels
SET mobility_type = 'Other'
WHERE mobility_type NOT IN (
    'Faculty Exchange', 'Teaching Mobility', 'Research Mobility',
    'International Training', 'International Conference',
    'Visiting Professorship/Scholarship', 'Fellowship',
    'Short-Term Study Program', 'International Collaborative Research',
    'International Community Extension Engagement', 'International Benchmarking',
    'Other'
);

-- Task 7: Normalize Mobility Duration to the 5 categories
UPDATE system_core.travels
SET mobility_duration = CASE
    WHEN mobility_duration IN ('Short-Term', 'Short Term', '< 1 month') THEN 'Short-Term'
    WHEN mobility_duration IN ('Medium-Term', 'Medium Term', '1-6 months') THEN 'Medium-Term'
    WHEN mobility_duration IN ('Long-Term', 'Long Term', '> 6 months') THEN 'Long-Term'
    WHEN mobility_duration IN ('One Semester', 'One Academic Term', 'One Academic Term/Semester')
        THEN 'One Academic Term/Semester'
    WHEN mobility_duration = 'One Academic Year' THEN 'One Academic Year'
    ELSE NULL
END
WHERE mobility_duration IS NOT NULL;

-- Recompute duration from dates where still NULL
UPDATE system_core.travels
SET mobility_duration = CASE
    WHEN (end_date - start_date) + 1 <= 30 THEN 'Short-Term'
    WHEN (end_date - start_date) + 1 <= 183 THEN 'Medium-Term'
    WHEN (end_date - start_date) + 1 <= 366 THEN 'Long-Term'
    ELSE 'One Academic Year'
END
WHERE mobility_duration IS NULL AND start_date IS NOT NULL AND end_date IS NOT NULL;

-- Normalize Follow Up to workbook vocabulary (Done / Not Yet / Ongoing)
UPDATE system_core.travels
SET follow_up = CASE
    WHEN follow_up IN ('Done', 'None needed', 'Completed', 'Complete')
        THEN 'Done'
    WHEN follow_up IN ('Ongoing', 'In Progress')
        THEN 'Ongoing'
    WHEN follow_up IS NOT NULL AND TRIM(follow_up) <> ''
        THEN 'Not Yet'
    ELSE NULL
END;

-- Enforce constraints going forward
ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_mobility_type;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_mobility_type
    CHECK (mobility_type IN (
        'Faculty Exchange', 'Teaching Mobility', 'Research Mobility',
        'International Training', 'International Conference',
        'Visiting Professorship/Scholarship', 'Fellowship',
        'Short-Term Study Program', 'International Collaborative Research',
        'International Community Extension Engagement', 'International Benchmarking',
        'Other'
    ));

ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_mobility_duration;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_mobility_duration
    CHECK (mobility_duration IS NULL OR mobility_duration IN (
        'Short-Term', 'Medium-Term', 'Long-Term',
        'One Academic Term/Semester', 'One Academic Year'
    ));

ALTER TABLE system_core.travels
    DROP CONSTRAINT IF EXISTS chk_follow_up;
ALTER TABLE system_core.travels
    ADD CONSTRAINT chk_follow_up
    CHECK (follow_up IS NULL OR follow_up IN ('Done', 'Not Yet', 'Ongoing'));

-- Helpful index for registry filters
CREATE INDEX IF NOT EXISTS idx_travels_mobility_type
    ON system_core.travels(mobility_type);

COMMENT ON COLUMN system_core.travels.mobility_type IS 'Type of Mobility (workbook Task 1 - 11 official values + Other)';
COMMENT ON COLUMN system_core.travels.mobility_duration IS 'Mobility Duration category (workbook Task 7)';
COMMENT ON COLUMN system_core.travels.follow_up IS 'Follow Up status (Done / Not Yet / Ongoing)';

COMMIT;
