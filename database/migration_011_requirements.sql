-- Migration 011: Official OIGE requirement checklists (boss's source PDFs).
-- Master list of requirements per participant type + phase, with completeness
-- tracking support. Documents match requirements by exact doc_type name.

CREATE TABLE IF NOT EXISTS system_core.requirement_items (
    requirement_id SERIAL PRIMARY KEY,
    applies_to VARCHAR(20) NOT NULL,
    phase VARCHAR(20) NOT NULL,
    name VARCHAR(150) NOT NULL,
    parent_id INTEGER REFERENCES system_core.requirement_items(requirement_id),
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    condition_text VARCHAR(200),
    has_template BOOLEAN NOT NULL DEFAULT FALSE,
    template_key VARCHAR(50),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_req_applies_to CHECK (applies_to IN ('Faculty', 'Student')),
    CONSTRAINT chk_req_phase CHECK (phase IN ('Pre-Travel', 'Post-Travel')),
    CONSTRAINT uq_req_item UNIQUE (applies_to, phase, name)
);

-- ==================== FACULTY PRE-FOREIGN TRAVEL (Annex A, 16 items) ====================
INSERT INTO system_core.requirement_items (applies_to, phase, name, is_required, condition_text, has_template, template_key, sort_order) VALUES
    ('Faculty', 'Pre-Travel', 'Letter of Intent', TRUE, NULL, FALSE, NULL, 1),
    ('Faculty', 'Pre-Travel', 'Endorsement Letter (Immediate Supervisor)', TRUE, NULL, FALSE, NULL, 2),
    ('Faculty', 'Pre-Travel', 'Invitation Letter', TRUE, 'With attached conference brochure/program', FALSE, NULL, 3),
    ('Faculty', 'Pre-Travel', 'Proof of Acceptance', FALSE, 'If applicable', FALSE, NULL, 4),
    ('Faculty', 'Pre-Travel', 'CHED IAS Assessment', TRUE, 'Secure from OIGE — see attached sub-requirements', FALSE, NULL, 5),
    ('Faculty', 'Pre-Travel', 'Itinerary of Travel', TRUE, NULL, FALSE, NULL, 6),
    ('Faculty', 'Pre-Travel', 'Travel Order', TRUE, NULL, FALSE, NULL, 7),
    ('Faculty', 'Pre-Travel', 'Re-Entry Action Plan', TRUE, 'CSU/CHED template', TRUE, 'reentry_plan', 8),
    ('Faculty', 'Pre-Travel', 'Faculty Replacement', FALSE, 'If applicable — covers missed classes', FALSE, NULL, 9),
    ('Faculty', 'Pre-Travel', 'Special Order (OIC)', FALSE, 'For personnel with designation', FALSE, NULL, 10),
    ('Faculty', 'Pre-Travel', 'Certificate of Availability of Funds', FALSE, 'If funded (Accounting Office)', FALSE, NULL, 11),
    ('Faculty', 'Pre-Travel', 'Certificate of Budget Allocation', FALSE, 'If funded (Budget Office)', FALSE, NULL, 12),
    ('Faculty', 'Pre-Travel', 'Certificate of No Unliquidated Cash Advances', FALSE, 'Accounting Office', FALSE, NULL, 13),
    ('Faculty', 'Pre-Travel', 'Certificate of No Pending Project Terminal Report', FALSE, 'RDIE', FALSE, NULL, 14),
    ('Faculty', 'Pre-Travel', 'Certificate of Employment', TRUE, 'HRMS', FALSE, NULL, 15),
    ('Faculty', 'Pre-Travel', 'CS Form No. 7 Clearance', FALSE, 'If travel is 30 days or more', FALSE, NULL, 16),
    ('Faculty', 'Pre-Travel', 'CHED IAS: Invitation/Acceptance Letter', FALSE, 'CHED IAS sub-requirement (a)', FALSE, NULL, 17),
    ('Faculty', 'Pre-Travel', 'CHED IAS: Event Details', FALSE, 'CHED IAS sub-requirement (b)', FALSE, NULL, 18),
    ('Faculty', 'Pre-Travel', 'CHED IAS: Organizer Details', FALSE, 'CHED IAS sub-requirement (c)', FALSE, NULL, 19),
    ('Faculty', 'Pre-Travel', 'CHED IAS Form 15', FALSE, 'CHED IAS sub-requirement (d)', FALSE, NULL, 20),
    ('Faculty', 'Pre-Travel', 'Certificate of Urgency', FALSE, 'CHED IAS sub-requirement (e)', FALSE, NULL, 21),
    ('Faculty', 'Pre-Travel', 'Foreign Travel Monitoring Form', FALSE, 'CHED IAS sub-requirement (f) — attach MOVs', FALSE, NULL, 22),
    ('Faculty', 'Pre-Travel', 'Proof of Publication (Scopus/Elsevier/ACI)', FALSE, 'For paper presentations', FALSE, NULL, 23),
    ('Faculty', 'Pre-Travel', 'Re-Entry Action Plan (Previous Travel)', FALSE, 'CHED template — of previous travel', TRUE, 'reentry_plan', 24),
    ('Faculty', 'Pre-Travel', 'Travel Report of Previous Travel', FALSE, 'Post-travel report of previous travel', FALSE, NULL, 25),
    ('Faculty', 'Pre-Travel', 'Certificate of Event Legitimacy', FALSE, 'CHED IAS sub-requirement (j)', FALSE, NULL, 26)
ON CONFLICT (applies_to, phase, name) DO NOTHING;

UPDATE system_core.requirement_items c SET parent_id = p.requirement_id
FROM system_core.requirement_items p
WHERE p.applies_to = 'Faculty' AND p.phase = 'Pre-Travel' AND p.name = 'CHED IAS Assessment'
  AND c.applies_to = 'Faculty' AND c.phase = 'Pre-Travel'
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

-- ==================== FACULTY POST-FOREIGN TRAVEL (23 items) ====================
INSERT INTO system_core.requirement_items (applies_to, phase, name, is_required, condition_text, has_template, template_key, sort_order) VALUES
    ('Faculty', 'Post-Travel', 'Letter of Intent', TRUE, 'Approved', FALSE, NULL, 1),
    ('Faculty', 'Post-Travel', 'Endorsement Letter (Immediate Supervisor)', TRUE, NULL, FALSE, NULL, 2),
    ('Faculty', 'Post-Travel', 'Upward Transmittal Letter (DAA to OP)', TRUE, NULL, FALSE, NULL, 3),
    ('Faculty', 'Post-Travel', 'Invitation Letter', TRUE, 'With conference brochure/program', FALSE, NULL, 4),
    ('Faculty', 'Post-Travel', 'Proof of Acceptance', FALSE, 'If applicable', FALSE, NULL, 5),
    ('Faculty', 'Post-Travel', 'CHED IAS Assessment', TRUE, 'With attached documents a-j', FALSE, NULL, 6),
    ('Faculty', 'Post-Travel', 'Actual Itinerary of Travel', TRUE, 'Duly signed actual itinerary + approved itinerary', FALSE, NULL, 7),
    ('Faculty', 'Post-Travel', 'Travel Order', TRUE, 'Approved', FALSE, NULL, 8),
    ('Faculty', 'Post-Travel', 'Re-Entry Action Plan', TRUE, 'HR template', TRUE, 'reentry_plan', 9),
    ('Faculty', 'Post-Travel', 'Faculty Replacement', FALSE, 'If applicable', FALSE, NULL, 10),
    ('Faculty', 'Post-Travel', 'Special Order (OIC)', FALSE, 'With designation', FALSE, NULL, 11),
    ('Faculty', 'Post-Travel', 'Certificate of Availability of Funds', FALSE, 'If funded', FALSE, NULL, 12),
    ('Faculty', 'Post-Travel', 'Certificate of Budget Allocation', FALSE, 'If funded', FALSE, NULL, 13),
    ('Faculty', 'Post-Travel', 'Certificate of No Unliquidated Cash Advances', FALSE, NULL, FALSE, NULL, 14),
    ('Faculty', 'Post-Travel', 'Certificate of No Pending Project Terminal Report', FALSE, NULL, FALSE, NULL, 15),
    ('Faculty', 'Post-Travel', 'Certificate of Employment', TRUE, NULL, FALSE, NULL, 16),
    ('Faculty', 'Post-Travel', 'CS Form No. 7 Clearance', FALSE, 'If travel is 30 days or more', FALSE, NULL, 17),
    ('Faculty', 'Post-Travel', 'Travel Authority', TRUE, NULL, FALSE, NULL, 18),
    ('Faculty', 'Post-Travel', 'BOR Resolution/Referendum', TRUE, NULL, FALSE, NULL, 19),
    ('Faculty', 'Post-Travel', 'Boarding Passes / E-Tickets', TRUE, NULL, FALSE, NULL, 20),
    ('Faculty', 'Post-Travel', 'Certificate of Participation/Completion', TRUE, NULL, FALSE, NULL, 21),
    ('Faculty', 'Post-Travel', 'Travel Report', TRUE, 'Post-travel report', FALSE, NULL, 22),
    ('Faculty', 'Post-Travel', 'Other supporting documents as required', FALSE, NULL, FALSE, NULL, 23)
ON CONFLICT (applies_to, phase, name) DO NOTHING;

-- ==================== STUDENT POST-FOREIGN TRAVEL (28 items) ====================
INSERT INTO system_core.requirement_items (applies_to, phase, name, is_required, condition_text, has_template, template_key, sort_order) VALUES
    ('Student', 'Post-Travel', 'Letter of Intent', TRUE, 'Approved', FALSE, NULL, 1),
    ('Student', 'Post-Travel', 'Endorsement Letter (College Dean)', TRUE, NULL, FALSE, NULL, 2),
    ('Student', 'Post-Travel', 'Upward Transmittal Letter (DSAS to OP)', TRUE, NULL, FALSE, NULL, 3),
    ('Student', 'Post-Travel', 'Invitation Letter', TRUE, 'With conference brochure/program', FALSE, NULL, 4),
    ('Student', 'Post-Travel', 'Proof of Acceptance', FALSE, 'If applicable', FALSE, NULL, 5),
    ('Student', 'Post-Travel', 'CHED IAS Assessment', TRUE, NULL, FALSE, NULL, 6),
    ('Student', 'Post-Travel', 'CHED IAS Form 15', TRUE, NULL, FALSE, NULL, 7),
    ('Student', 'Post-Travel', 'Certificate of Urgency', TRUE, NULL, FALSE, NULL, 8),
    ('Student', 'Post-Travel', 'Proof of Publication (Scopus/Elsevier/ACI)', FALSE, 'For paper presentations', FALSE, NULL, 9),
    ('Student', 'Post-Travel', 'Re-Entry Action Plan', TRUE, 'CHED template', TRUE, 'reentry_plan', 10),
    ('Student', 'Post-Travel', 'Travel Report of Previous Travel', FALSE, 'If previous travel', FALSE, NULL, 11),
    ('Student', 'Post-Travel', 'Certificate of Event Legitimacy', TRUE, NULL, FALSE, NULL, 12),
    ('Student', 'Post-Travel', 'Itinerary of Travel', TRUE, 'Approved itinerary', FALSE, NULL, 13),
    ('Student', 'Post-Travel', 'Actual Itinerary of Travel', TRUE, 'Duly signed actual itinerary', FALSE, NULL, 14),
    ('Student', 'Post-Travel', 'Travel Order', TRUE, 'Approved', FALSE, NULL, 15),
    ('Student', 'Post-Travel', 'Certificate of Availability of Funds', FALSE, 'If applicable', FALSE, NULL, 16),
    ('Student', 'Post-Travel', 'Certificate of Budget Allocation', FALSE, 'If applicable', FALSE, NULL, 17),
    ('Student', 'Post-Travel', 'Certificate of No Unliquidated Cash Advances', FALSE, 'If applicable', FALSE, NULL, 18),
    ('Student', 'Post-Travel', 'Travel Authority', TRUE, NULL, FALSE, NULL, 19),
    ('Student', 'Post-Travel', 'Endorsement Letter to CHED', TRUE, NULL, FALSE, NULL, 20),
    ('Student', 'Post-Travel', 'Selection Scoring', TRUE, NULL, FALSE, NULL, 21),
    ('Student', 'Post-Travel', 'Certificate of Selection Scoring', TRUE, NULL, FALSE, NULL, 22),
    ('Student', 'Post-Travel', 'ANNEX A and B of CMO 26 Requirements', TRUE, NULL, FALSE, NULL, 23),
    ('Student', 'Post-Travel', 'IZN Student Screening Committee Referendum', TRUE, NULL, FALSE, NULL, 24),
    ('Student', 'Post-Travel', 'CHED Endorsement to Bureau of Immigration', TRUE, NULL, FALSE, NULL, 25),
    ('Student', 'Post-Travel', 'BOR Resolution/Referendum', TRUE, NULL, FALSE, NULL, 26),
    ('Student', 'Post-Travel', 'Flight Itinerary', TRUE, NULL, FALSE, NULL, 27),
    ('Student', 'Post-Travel', 'Boarding Passes', TRUE, NULL, FALSE, NULL, 28),
    ('Student', 'Post-Travel', 'Other supporting documents as required', FALSE, NULL, FALSE, NULL, 29)
ON CONFLICT (applies_to, phase, name) DO NOTHING;

-- ==================== Document Types: official checklist names (admin catalog) ====================
INSERT INTO system_core.document_types (name, category, is_required, description, sort_order) VALUES
    ('Letter of Intent', 'Pre-Travel', TRUE, 'Official checklist requirement (Faculty/Student)', 10),
    ('Endorsement Letter (Immediate Supervisor)', 'Pre-Travel', TRUE, 'Faculty checklist requirement', 11),
    ('Endorsement Letter (College Dean)', 'Pre-Travel', TRUE, 'Student checklist requirement', 12),
    ('Upward Transmittal Letter (DAA to OP)', 'Pre-Travel', TRUE, 'Faculty post-travel requirement', 13),
    ('Upward Transmittal Letter (DSAS to OP)', 'Pre-Travel', TRUE, 'Student post-travel requirement', 14),
    ('Proof of Acceptance', 'Pre-Travel', FALSE, 'If applicable', 15),
    ('CHED IAS Assessment', 'Pre-Travel', TRUE, 'Secure from OIGE', 16),
    ('CHED IAS Form 15', 'Pre-Travel', TRUE, 'CHED template', 17),
    ('Certificate of Urgency', 'Pre-Travel', TRUE, NULL, 18),
    ('Foreign Travel Monitoring Form', 'Pre-Travel', TRUE, 'Attach MOVs', 19),
    ('Proof of Publication (Scopus/Elsevier/ACI)', 'Pre-Travel', FALSE, 'For paper presentations', 20),
    ('Re-Entry Action Plan', 'Pre-Travel', True, 'CSU/CHED template — downloadable in Requirements', 21),
    ('Certificate of Event Legitimacy', 'Pre-Travel', TRUE, NULL, 22),
    ('Itinerary of Travel', 'Pre-Travel', TRUE, 'Approved itinerary', 23),
    ('Faculty Replacement', 'Pre-Travel', FALSE, 'If applicable', 24),
    ('Special Order (OIC)', 'Pre-Travel', FALSE, 'For personnel with designation', 25),
    ('Certificate of Availability of Funds', 'Pre-Travel', FALSE, 'If funded (Accounting)', 26),
    ('Certificate of Budget Allocation', 'Pre-Travel', FALSE, 'If funded (Budget)', 27),
    ('Certificate of No Unliquidated Cash Advances', 'Pre-Travel', FALSE, 'Accounting', 28),
    ('Certificate of No Pending Project Terminal Report', 'Pre-Travel', FALSE, 'RDIE', 29),
    ('Certificate of Employment', 'Pre-Travel', TRUE, 'HRMS', 30),
    ('CS Form No. 7 Clearance', 'Pre-Travel', FALSE, 'If travel is 30 days or more', 31),
    ('Actual Itinerary of Travel', 'Post-Travel', TRUE, 'Duly signed', 40),
    ('BOR Resolution/Referendum', 'Post-Travel', TRUE, NULL, 41),
    ('Boarding Passes / E-Tickets', 'Post-Travel', TRUE, NULL, 42),
    ('Certificate of Participation/Completion', 'Post-Travel', TRUE, NULL, 43),
    ('Endorsement Letter to CHED', 'Post-Travel', TRUE, 'Student requirement', 44),
    ('Selection Scoring', 'Post-Travel', TRUE, 'Student requirement', 45),
    ('Certificate of Selection Scoring', 'Post-Travel', TRUE, 'Student requirement', 46),
    ('ANNEX A and B of CMO 26 Requirements', 'Post-Travel', TRUE, 'Student requirement', 47),
    ('IZN Student Screening Committee Referendum', 'Post-Travel', TRUE, 'Student requirement', 48),
    ('CHED Endorsement to Bureau of Immigration', 'Post-Travel', TRUE, 'Student requirement', 49),
    ('Flight Itinerary', 'Post-Travel', TRUE, 'Student requirement', 50),
    ('Boarding Passes', 'Post-Travel', TRUE, 'Student requirement', 51),
    ('Other supporting documents as required', 'Post-Travel', FALSE, NULL, 52)
ON CONFLICT (name) DO NOTHING;
