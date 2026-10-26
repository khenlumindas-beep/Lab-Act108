-- Phase 3: Post-travel evidence storage (BR-05, FR-F07).
-- Mirrors reentry_activities.evidence_path so faculty can attach a file to a
-- post-travel deliverable and have it verified by admin.
ALTER TABLE system_core.post_travel_requirements
    ADD COLUMN IF NOT EXISTS evidence_path VARCHAR(500);
