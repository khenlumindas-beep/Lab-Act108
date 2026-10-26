-- Migration 006: Type of Funding Support - workbook-exact vocabulary (Tasks note #5)
-- Renames legacy 'TBD' to 'To Be Determined' and adds strict CHECK monitoring.

-- 1. Update any legacy rows (safe no-op if none)
UPDATE system_core.travels
   SET funding_type = 'To Be Determined'
 WHERE funding_type = 'TBD';

UPDATE system_core.mobility_plans
   SET funding_type = 'To Be Determined'
 WHERE funding_type = 'TBD';

-- 2. Strict monitoring CHECK on travels (5 workbook values)
ALTER TABLE system_core.travels
  DROP CONSTRAINT IF EXISTS chk_funding_type;

ALTER TABLE system_core.travels
  ADD CONSTRAINT chk_funding_type
  CHECK (funding_type IS NULL OR funding_type IN
         ('Fully Funded', 'Partially Funded', 'Self-Funded',
          'No Funding Required', 'To Be Determined'));
