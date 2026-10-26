-- Phase 6 fix: record_remark() callers were silently failing chk_remark_type /
-- chk_remark_action. Extend both allow-lists with the values the lifecycle
-- routes actually write (post-travel / re-entry remarks, blocking statuses).
ALTER TABLE system_core.remark_history DROP CONSTRAINT IF EXISTS chk_remark_type;
ALTER TABLE system_core.remark_history ADD CONSTRAINT chk_remark_type CHECK (
    remark_type IS NULL OR remark_type IN (
        'Missing Document','Incorrect Document','Expired','Illegible',
        'Missing Signature','Wrong Document Type','Post-Travel Pending',
        'Re-entry Overdue','General',
        -- lifecycle route values (post_travel.py, reentry.py)
        'Post-Travel','Re-Entry'
    )
);

ALTER TABLE system_core.remark_history DROP CONSTRAINT IF EXISTS chk_remark_action;
ALTER TABLE system_core.remark_history ADD CONSTRAINT chk_remark_action CHECK (
    action IS NULL OR action IN (
        'For Verification','For Resubmission','Follow Up','Approved',
        'Rejected','No Further Action','General',
        -- blocking-status marker used by post_travel/reentry updates
        'Resubmission Required'
    )
);
