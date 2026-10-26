-- Migration 005: travels.risk_score (ML score used by analytics)
-- Applied: 2026-10-14

ALTER TABLE system_core.travels
    ADD COLUMN IF NOT EXISTS risk_score DOUBLE PRECISION;

COMMENT ON COLUMN system_core.travels.risk_score IS 'ML-computed numeric risk score (0-1)';
