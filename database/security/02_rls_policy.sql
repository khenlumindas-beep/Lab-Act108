------------------------------------------------------------------------------
-- SmartTrack — IT108 Activity 7, Part D
-- Row-Level Security (RLS) decision: YES — one policy, project-specific
--
-- Protected table : system_core.travels  (core mobility records)
-- Row ownership   : travels.user_id -> users.user_id (record owner)
-- Allowed ops     : faculty = own rows only (SELECT/INSERT/UPDATE);
--                   super_admin = all rows.
-- Identity source : PostgreSQL session setting app.current_user_id, supplied
--                   by the backend per request from the verified JWT claims:
--
--                       SET LOCAL app.current_user_id = <current_user.user_id>
--
--                   (set inside the request's transaction; the value never
--                   comes from client-supplied SQL — the backend binds it as
--                   a parameter when issuing the SET.)
--
-- Fail-closed: if the GUC is unset/NULL the policy evaluates to NULL, so the
--              role sees NO rows and cannot insert rows (WITH CHECK fails).
--
-- SAFETY: tested in the sandbox database smarttrack_security_lab. On the
--         live DB the table owner (postgres) bypasses RLS unless FORCE ROW
--         SECURITY is set, so applying this file first is a no-op for the
--         current backend account; enable FORCE only after the backend
--         sends app.current_user_id on every request.
------------------------------------------------------------------------------

ALTER TABLE system_core.travels ENABLE ROW LEVEL SECURITY;

-- Admin policy: full access (a role with RLS enabled and no policy would be
-- denied everything, so the admin policy must exist explicitly).
DROP POLICY IF EXISTS travels_admin_all ON system_core.travels;
CREATE POLICY travels_admin_all ON system_core.travels
    FOR ALL TO smarttrack_super_admin
    USING (true)
    WITH CHECK (true);

-- Faculty policy: own rows only, based on record ownership.
-- NULLIF(...) keeps the policy FAIL-CLOSED: an unset or empty identity
-- becomes NULL, so the predicate is NULL -> no rows visible / no insert.
DROP POLICY IF EXISTS travels_faculty_own_rows ON system_core.travels;
CREATE POLICY travels_faculty_own_rows ON system_core.travels
    FOR ALL TO smarttrack_faculty
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::integer)
    WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::integer);

-- Optional hardening (DO NOT enable until the backend supplies the GUC):
-- ALTER TABLE system_core.travels FORCE ROW LEVEL SECURITY;

-- Evidence: show the policies attached to the table
SELECT schemaname, tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'system_core' AND tablename = 'travels'
ORDER BY policyname;
