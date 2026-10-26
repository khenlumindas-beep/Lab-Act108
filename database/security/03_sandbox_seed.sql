------------------------------------------------------------------------------
-- SmartTrack — IT108 Activity 7
-- Sandbox seed: SAFE TEST RECORDS ONLY (never real user data)
-- Target database: smarttrack_security_lab (copied schema from smarttrack_db)
-- Idempotent: re-running does not duplicate rows.
------------------------------------------------------------------------------

-- Reference data (needed by FKs) --------------------------------------------
INSERT INTO system_core.colleges (college_id, code, name)
OVERRIDING SYSTEM VALUE
VALUES (9001, 'LAB-COL', 'Lab Test College')
ON CONFLICT (college_id) DO NOTHING;

INSERT INTO system_core.departments (department_id, college_id, code, name)
OVERRIDING SYSTEM VALUE
VALUES (9001, 9001, 'LAB-DEPT', 'Lab Test Department')
ON CONFLICT (department_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.colleges',  'college_id'),
              (SELECT MAX(college_id)  FROM system_core.colleges));
SELECT setval(pg_get_serial_sequence('system_core.departments', 'department_id'),
              (SELECT MAX(department_id) FROM system_core.departments));

-- Test users (2 roles, fake credentials) ------------------------------------
INSERT INTO system_core.users
    (user_id, full_name, email, password_hash, role, college_id, department_id, is_active)
OVERRIDING SYSTEM VALUE
VALUES
    (9001, 'Lab Faculty Tester', 'lab.faculty@test.invalid',
     'TEST-NOT-A-REAL-HASH-lab-faculty', 'faculty',     9001, 9001, TRUE),
    (9002, 'Lab Admin Tester',   'lab.admin@test.invalid',
     'TEST-NOT-A-REAL-HASH-lab-admin',   'super_admin', 9001, 9001, TRUE)
ON CONFLICT (user_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.users', 'user_id'),
              (SELECT MAX(user_id) FROM system_core.users));

-- Test travels (one owned by each test user + one disposable row) -----------
INSERT INTO system_core.travels
    (travel_id, user_id, college_id, department_id, participant_type,
     event_title, mobility_type, start_date, end_date, location, country)
OVERRIDING SYSTEM VALUE
VALUES
    (9101, 9001, 9001, 9001, 'Faculty',
     'LAB TEST — Faculty mobility (own row of faculty tester)',
     'Teaching Mobility', DATE '2026-01-12', DATE '2026-01-20',
     'Lab City', 'Labland'),
    (9102, 9002, 9001, 9001, 'Faculty',
     'LAB TEST — Admin mobility (admin-owned row)',
     'Teaching Mobility', DATE '2026-02-12', DATE '2026-02-20',
     'Lab City', 'Labland'),
    (9103, 9002, 9001, 9001, 'Faculty',
     'LAB TEST — disposable row for the admin DELETE test',
     'Teaching Mobility', DATE '2026-03-12', DATE '2026-03-20',
     'Lab City', 'Labland')
ON CONFLICT (travel_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.travels', 'travel_id'),
              (SELECT MAX(travel_id) FROM system_core.travels));

-- Test documents ------------------------------------------------------------
INSERT INTO system_core.documents
    (document_id, travel_id, doc_type, doc_category, file_name, file_path, status)
OVERRIDING SYSTEM VALUE
VALUES
    (9201, 9101, 'Passport', 'Pre-Travel', 'lab-passport.txt',
     'lab/9201_lab-passport.txt', 'Pending'),
    (9202, 9102, 'Passport', 'Pre-Travel', 'lab-passport.txt',
     'lab/9202_lab-passport.txt', 'Pending')
ON CONFLICT (document_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.documents', 'document_id'),
              (SELECT MAX(document_id) FROM system_core.documents));

-- Test notifications --------------------------------------------------------
INSERT INTO system_core.notifications
    (notification_id, user_id, travel_id, title, message, type, is_read)
OVERRIDING SYSTEM VALUE
VALUES
    (9301, 9001, 9101, 'LAB TEST notification (faculty)',
     'Safe test record.', 'info', FALSE),
    (9302, 9002, 9102, 'LAB TEST notification (admin)',
     'Safe test record.', 'info', FALSE)
ON CONFLICT (notification_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.notifications', 'notification_id'),
              (SELECT MAX(notification_id) FROM system_core.notifications));

-- Test audit rows -----------------------------------------------------------
INSERT INTO system_core.audit_logs
    (audit_id, user_id, entity_type, entity_id, action, description)
OVERRIDING SYSTEM VALUE
VALUES
    (9401, 9002, 'travel', 9101, 'create', 'LAB TEST audit row (seed).')
ON CONFLICT (audit_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('system_core.audit_logs', 'audit_id'),
              (SELECT MAX(audit_id) FROM system_core.audit_logs));

-- Seed summary --------------------------------------------------------------
SELECT 'users'        AS tbl, COUNT(*) FROM system_core.users
UNION ALL SELECT 'travels',      COUNT(*) FROM system_core.travels
UNION ALL SELECT 'documents',    COUNT(*) FROM system_core.documents
UNION ALL SELECT 'notifications',COUNT(*) FROM system_core.notifications
UNION ALL SELECT 'audit_logs',   COUNT(*) FROM system_core.audit_logs;
