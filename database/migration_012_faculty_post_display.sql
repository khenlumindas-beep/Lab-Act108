-- Migration 012: Official-document display for the Faculty Post-Travel checklist.
-- Adds display_text (verbatim wording from the official HR&OIGE PDF) and seeds
-- the CHED IAS a-j sub-requirements as children of the Post-Travel CHED IAS
-- Assessment item (mirrors migration_011's Pre-Travel pattern). The `name`
-- column stays unchanged so document matching by exact doc_type keeps working.

ALTER TABLE system_core.requirement_items
    ADD COLUMN IF NOT EXISTS display_text VARCHAR(400);

-- ==================== PDF-verbatim wording (23 top-level items) ====================
UPDATE system_core.requirement_items SET display_text = 'Approved Letter of Intent'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Letter of Intent';
UPDATE system_core.requirement_items SET display_text = 'Endorsement Letter from the Immediate Supervisor'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Endorsement Letter (Immediate Supervisor)';
UPDATE system_core.requirement_items SET display_text = 'Upward Transmittal Letter from DAA to OP'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Upward Transmittal Letter (DAA to OP)';
UPDATE system_core.requirement_items SET display_text = 'Invitation Letter with attached copy of conference brochure or program and/or details of the activity'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Invitation Letter';
UPDATE system_core.requirement_items SET display_text = 'Proof of Acceptance (if applicable)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Proof of Acceptance';
UPDATE system_core.requirement_items SET display_text = 'CHED IAS Assessment and other attached documents for the request'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'CHED IAS Assessment';
UPDATE system_core.requirement_items SET display_text = 'Approved Itinerary of Travel and Actual Itinerary of Travel'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Actual Itinerary of Travel';
UPDATE system_core.requirement_items SET display_text = 'Approved Travel Order'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Travel Order';
UPDATE system_core.requirement_items SET display_text = 'Re-Entry Action Plan (HR Template)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Re-Entry Action Plan';
UPDATE system_core.requirement_items SET display_text = 'Faculty Replacement (if applicable)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Faculty Replacement';
UPDATE system_core.requirement_items SET display_text = 'Special Order (with designation)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Special Order (OIC)';
UPDATE system_core.requirement_items SET display_text = 'Certificate of Availability of Funds (if applicable)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of Availability of Funds';
UPDATE system_core.requirement_items SET display_text = 'Certificate of Budget Allocation (if applicable)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of Budget Allocation';
UPDATE system_core.requirement_items SET display_text = 'Certificate of No Unliquidated Cash Advances (if applicable)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of No Unliquidated Cash Advances';
UPDATE system_core.requirement_items SET display_text = 'Certificate of No Pending Project Terminal Report'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of No Pending Project Terminal Report';
UPDATE system_core.requirement_items SET display_text = 'Certificate of Employment'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of Employment';
UPDATE system_core.requirement_items SET display_text = 'CS Form No. 7 Clearance (for travel 30 days or more)'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'CS Form No. 7 Clearance';
UPDATE system_core.requirement_items SET display_text = 'Travel Authority'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Travel Authority';
UPDATE system_core.requirement_items SET display_text = 'BOR Resolution/Referendum'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'BOR Resolution/Referendum';
UPDATE system_core.requirement_items SET display_text = 'Boarding Passes / E-Tickets'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Boarding Passes / E-Tickets';
UPDATE system_core.requirement_items SET display_text = 'Certificate of Participation/Completion'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Certificate of Participation/Completion';
UPDATE system_core.requirement_items SET display_text = 'Post-Travel Report'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Travel Report';
UPDATE system_core.requirement_items SET display_text = 'Other supporting documents relevant to the travel'
    WHERE applies_to = 'Faculty' AND phase = 'Post-Travel' AND name = 'Other supporting documents as required';

-- ==================== CHED IAS a-j sub-requirements (children, not counted) ====================
INSERT INTO system_core.requirement_items
    (applies_to, phase, name, is_required, condition_text, has_template, template_key, sort_order, display_text)
VALUES
    ('Faculty', 'Post-Travel', 'CHED IAS: Invitation/Acceptance Letter', FALSE, NULL, FALSE, NULL, 24,
     'Invitation/Acceptance Letter'),
    ('Faculty', 'Post-Travel', 'CHED IAS: Event Details', FALSE, NULL, FALSE, NULL, 25,
     'Detailed information about the event'),
    ('Faculty', 'Post-Travel', 'CHED IAS: Organizer Details', FALSE, NULL, FALSE, NULL, 26,
     'Detailed information about the organizer'),
    ('Faculty', 'Post-Travel', 'CHED IAS Form 15', FALSE, NULL, FALSE, NULL, 27,
     'Filled-out CHED IAS Form 15 (paste link of Certificate of Event Legitimacy & Re-Entry Action Plan of previous travel; write "No previous travel" if none) (CHED Template)'),
    ('Faculty', 'Post-Travel', 'Certificate of Urgency', FALSE, NULL, FALSE, NULL, 28,
     'Certificate of Urgency'),
    ('Faculty', 'Post-Travel', 'Foreign Travel Monitoring Form', FALSE, NULL, FALSE, NULL, 29,
     'Foreign Travel Monitoring Form (previous travel) (attach MOVs)'),
    ('Faculty', 'Post-Travel', 'Proof of Publication (Scopus/Elsevier/ACI)', FALSE, NULL, FALSE, NULL, 30,
     'Proof that papers presented will be published in journals indexed by Elsevier/Scopus/ASEAN Citation Index (ACI)'),
    ('Faculty', 'Post-Travel', 'Re-Entry Action Plan (Previous Travel)', FALSE, NULL, FALSE, NULL, 31,
     'Re-Entry Action Plan (for training/seminar and fellowship) of previous travel (CHED Template)'),
    ('Faculty', 'Post-Travel', 'Travel Report of Previous Travel', FALSE, NULL, FALSE, NULL, 32,
     'Travel report of previous travel (Post Travel Report)'),
    ('Faculty', 'Post-Travel', 'Certificate of Event Legitimacy', FALSE, NULL, FALSE, NULL, 33,
     'Certificate of Event Legitimacy')
ON CONFLICT (applies_to, phase, name) DO NOTHING;

UPDATE system_core.requirement_items c SET parent_id = p.requirement_id
FROM system_core.requirement_items p
WHERE p.applies_to = 'Faculty' AND p.phase = 'Post-Travel' AND p.name = 'CHED IAS Assessment'
  AND c.applies_to = 'Faculty' AND c.phase = 'Post-Travel'
  AND c.parent_id IS NULL
  AND c.name IN (
    'CHED IAS: Invitation/Acceptance Letter',
    'CHED IAS: Event Details',
    'CHED IAS: Organizer Details',
    'CHED IAS Form 15',
    'Certificate of Urgency',
    'Foreign Travel Monitoring Form',
    'Proof of Publication (Scopus/Elsevier/ACI)',
    'Re-Entry Action Plan (Previous Travel)',
    'Travel Report of Previous Travel',
    'Certificate of Event Legitimacy'
  );
