------------------------------------------------------------------------------
-- SmartTrack — IT108 Activity 7, Part C
-- Project-specific GRANT / REVOKE statements (least privilege)
--
-- System:  SmartTrack — AI-Assisted International Mobility & Foreign Travel
--          Management System (CSUCC OIGE)
-- Schema:  system_core
-- Roles:   mirror the two application roles the backend actually recognizes
--          (backend/models.py  -> users.role IN ('super_admin','faculty'))
--
-- Selected sensitive tables (Part B): users, travels, documents,
--                                     notifications, audit_logs
--
-- SAFETY: Run against a SANDBOX database first (smarttrack_security_lab).
--         Apply to live smarttrack_db only as a deliberate, reviewed step.
--         CREATE ROLE is cluster-wide; GRANT/REVOKE only affect the
--         database you are connected to.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Step 1 — Create database roles (idempotent)
------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smarttrack_super_admin') THEN
        CREATE ROLE smarttrack_super_admin NOLOGIN;   -- maps to app role 'super_admin'
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smarttrack_faculty') THEN
        CREATE ROLE smarttrack_faculty NOLOGIN;       -- maps to app role 'faculty'
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smarttrack_app') THEN
        -- Backend service account (least-privilege: NO superuser/createdb/createrole).
        -- Password is set out-of-band by the DBA and stored only in backend/.env:
        --   ALTER ROLE smarttrack_app PASSWORD '<generated, never committed>';
        CREATE ROLE smarttrack_app NOLOGIN;
    END IF;
END
$$;

------------------------------------------------------------------------------
-- Step 2 — Schema usage (needed before any table access)
------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA system_core TO smarttrack_super_admin;
GRANT USAGE ON SCHEMA system_core TO smarttrack_faculty;
GRANT USAGE ON SCHEMA system_core TO smarttrack_app;

------------------------------------------------------------------------------
-- Step 3 — GRANT (matrix-driven, per selected table)
------------------------------------------------------------------------------
-- 3.1 super_admin: full workflow management on the 5 selected tables,
--     EXCEPT the least-privilege carve-outs shown in Step 4 (REVOKEs).
GRANT SELECT, INSERT, UPDATE, DELETE
    ON system_core.users, system_core.travels, system_core.documents,
       system_core.notifications, system_core.audit_logs
    TO smarttrack_super_admin;

-- 3.2 faculty: only the tables the faculty role actually uses.
GRANT SELECT
    ON system_core.travels, system_core.documents, system_core.notifications
    TO smarttrack_faculty;
GRANT INSERT, UPDATE
    ON system_core.travels, system_core.documents, system_core.notifications
    TO smarttrack_faculty;

-- 3.3 Sequences: faculty must be able to allocate keys for rows it inserts.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA system_core
    TO smarttrack_super_admin, smarttrack_faculty;

------------------------------------------------------------------------------
-- Step 4 — REVOKE (least-privilege corrections; >= 1 required by Part C)
------------------------------------------------------------------------------
-- 4.1 Faculty can never remove mobility records (audit-trail integrity).
REVOKE DELETE ON system_core.travels       FROM smarttrack_faculty;
REVOKE DELETE ON system_core.documents     FROM smarttrack_faculty;
REVOKE DELETE ON system_core.notifications FROM smarttrack_faculty;

-- 4.2 Faculty has NO access to user accounts (the backend serves the own-
--     profile view; account changes are admin-only).
REVOKE ALL ON system_core.users FROM smarttrack_faculty;

-- 4.3 Faculty cannot read or write the security audit trail.
REVOKE ALL ON system_core.audit_logs FROM smarttrack_faculty;

-- 4.4 Even the admin never hard-deletes users: accounts are deactivated
--     (users.is_active = false) so foreign keys and history stay intact.
REVOKE DELETE ON system_core.users FROM smarttrack_super_admin;

-- 4.5 Audit trail is append-only: no UPDATE/DELETE for anyone, incl. admin.
REVOKE UPDATE, DELETE ON system_core.audit_logs FROM smarttrack_super_admin;

------------------------------------------------------------------------------
-- Step 5 — Backend service account (Part E: "database account has only the
--          privileges needed by the backend").
--          One shared backend connection serves both app roles, so the
--          service account holds the UNION of their runtime privileges on
--          the schema tables — but no DDL, no superuser, no createdb.
--          Per-request role differentiation happens in the application
--          layer (JWT role) and, for row filtering, via RLS (02_rls_policy).
------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA system_core
    TO smarttrack_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA system_core
    TO smarttrack_app;
-- Allow the service account to SET ROLE into the two matrix roles later:
GRANT smarttrack_super_admin, smarttrack_faculty TO smarttrack_app;

------------------------------------------------------------------------------
-- Evidence query — verify the resulting access-control grants
------------------------------------------------------------------------------
SELECT grantee, table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.table_privileges
WHERE table_schema = 'system_core'
  AND grantee IN ('smarttrack_super_admin', 'smarttrack_faculty', 'smarttrack_app')
  AND table_name IN ('users','travels','documents','notifications','audit_logs')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;
