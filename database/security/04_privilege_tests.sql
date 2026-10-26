------------------------------------------------------------------------------
-- SmartTrack — IT108 Activity 7, Part C
-- Allowed / blocked action tests (run against smarttrack_security_lab)
--
-- Each test runs in its own transaction and is ROLLED BACK, so the sandbox
-- stays reusable. Errors below are EXPECTED for the BLOCKED tests.
-- Expected results are shown next to every test; actual results are captured
-- in evidence/privilege_test_results.txt.
------------------------------------------------------------------------------
\set ON_ERROR_STOP off
\pset pager off

\echo '=================================================================='
\echo 'SMARTTRACK DB SECURITY LAB - allowed/blocked action tests'
\echo '=================================================================='

------------------------------------------------------------------------------
-- T-01 (ALLOWED): super_admin sees all seeded travel rows
------------------------------------------------------------------------------
\echo '--- T-01 super_admin SELECT travels | EXPECT: allowed, count = 3'
BEGIN;
SET ROLE smarttrack_super_admin;
SELECT 'T-01 result' AS test, COUNT(*) AS visible_travels FROM system_core.travels;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-02 (ALLOWED): super_admin DELETE on the disposable test row
------------------------------------------------------------------------------
\echo '--- T-02 super_admin DELETE disposable row 9103 | EXPECT: allowed (1 row)'
BEGIN;
SET ROLE smarttrack_super_admin;
DELETE FROM system_core.travels WHERE travel_id = 9103;
SELECT 'T-02 result' AS test, COUNT(*) AS remaining_disposable_rows
FROM system_core.travels WHERE travel_id = 9103;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-03 (BLOCKED): faculty must NOT be able to delete travels
------------------------------------------------------------------------------
\echo '--- T-03 faculty DELETE travels | EXPECT: BLOCKED -> permission denied'
BEGIN;
SET ROLE smarttrack_faculty;
DELETE FROM system_core.travels;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-04 (BLOCKED): faculty has no access to user accounts
------------------------------------------------------------------------------
\echo '--- T-04 faculty UPDATE users | EXPECT: BLOCKED -> permission denied'
BEGIN;
SET ROLE smarttrack_faculty;
UPDATE system_core.users SET is_active = FALSE WHERE user_id = 9001;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-05 (BLOCKED): faculty cannot read password hashes
------------------------------------------------------------------------------
\echo '--- T-05 faculty SELECT password_hash FROM users | EXPECT: BLOCKED'
BEGIN;
SET ROLE smarttrack_faculty;
SELECT user_id, password_hash FROM system_core.users;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-06 (BLOCKED): faculty cannot write the audit trail
------------------------------------------------------------------------------
\echo '--- T-06 faculty INSERT INTO audit_logs | EXPECT: BLOCKED'
BEGIN;
SET ROLE smarttrack_faculty;
INSERT INTO system_core.audit_logs (user_id, entity_type, entity_id, action, description)
VALUES (9001, 'travel', 9101, 'other', 'should be rejected');
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-07 (ALLOWED + RLS): faculty with identity set sees ONLY own rows
------------------------------------------------------------------------------
\echo '--- T-07 faculty SELECT travels as user 9001 | EXPECT: allowed, count = 1 (own row only)'
BEGIN;
SET LOCAL app.current_user_id = '9001';
SET ROLE smarttrack_faculty;
SELECT 'T-07 result' AS test, COUNT(*) AS visible_travels FROM system_core.travels;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-08 (FAIL-CLOSED): faculty with NO identity sees zero rows
------------------------------------------------------------------------------
\echo '--- T-08 faculty SELECT travels without identity | EXPECT: allowed, count = 0 (fail-closed)'
BEGIN;
SET ROLE smarttrack_faculty;
SELECT 'T-08 result' AS test, COUNT(*) AS visible_travels FROM system_core.travels;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-09 (ALLOWED): faculty inserts a travel row owned by itself
------------------------------------------------------------------------------
\echo '--- T-09 faculty INSERT own travel row | EXPECT: allowed'
BEGIN;
SET LOCAL app.current_user_id = '9001';
SET ROLE smarttrack_faculty;
INSERT INTO system_core.travels
    (user_id, college_id, department_id, participant_type,
     event_title, mobility_type, start_date, end_date)
VALUES (9001, 9001, 9001, 'Faculty',
        'LAB TEST — faculty-created row (allowed)',
        'Teaching Mobility', DATE '2026-04-12', DATE '2026-04-20');
SELECT 'T-09 result' AS test, COUNT(*) AS inserted_rows
FROM system_core.travels WHERE event_title LIKE 'LAB TEST — faculty-created%';
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-10 (BLOCKED): faculty inserts a row owned by someone else (RLS WITH CHECK)
------------------------------------------------------------------------------
\echo '--- T-10 faculty INSERT row owned by user 9002 | EXPECT: BLOCKED -> row-level security violation'
BEGIN;
SET LOCAL app.current_user_id = '9001';
SET ROLE smarttrack_faculty;
INSERT INTO system_core.travels
    (user_id, college_id, department_id, participant_type,
     event_title, mobility_type, start_date, end_date)
VALUES (9002, 9001, 9001, 'Faculty',
        'LAB TEST — not owned by the writer (must fail)',
        'Teaching Mobility', DATE '2026-05-12', DATE '2026-05-20');
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-11 (ALLOWED): faculty updates its OWN travel row
------------------------------------------------------------------------------
\echo '--- T-11 faculty UPDATE own travel row 9101 | EXPECT: allowed (1 row)'
BEGIN;
SET LOCAL app.current_user_id = '9001';
SET ROLE smarttrack_faculty;
UPDATE system_core.travels
   SET remarks = 'LAB TEST — own-row update (allowed)'
 WHERE travel_id = 9101;
SELECT 'T-11 result' AS test, COUNT(*) AS updated_rows
FROM system_core.travels WHERE remarks LIKE 'LAB TEST — own-row update%';
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- T-12 (BLOCKED by RLS): faculty UPDATE of another user's row touches 0 rows
------------------------------------------------------------------------------
\echo '--- T-12 faculty UPDATE travel row 9102 (admin-owned) | EXPECT: blocked by RLS, 0 rows'
BEGIN;
SET LOCAL app.current_user_id = '9001';
SET ROLE smarttrack_faculty;
UPDATE system_core.travels
   SET remarks = 'LAB TEST — must not touch admin row'
 WHERE travel_id = 9102;
SELECT 'T-12 result' AS test, COUNT(*) AS visible_target_rows
FROM system_core.travels WHERE travel_id = 9102;
ROLLBACK;
RESET ROLE;

------------------------------------------------------------------------------
-- Evidence: resulting grants on the selected tables
------------------------------------------------------------------------------
\echo '--- EVIDENCE: table_privileges after GRANT/REVOKE'
SELECT grantee, table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.table_privileges
WHERE table_schema = 'system_core'
  AND grantee IN ('smarttrack_super_admin', 'smarttrack_faculty')
  AND table_name IN ('users','travels','documents','notifications','audit_logs')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo '=================================================================='
\echo 'END of tests'
\echo '=================================================================='
