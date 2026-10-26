# IT108 — Activity 7: PostgreSQL Database Security and Access Control

**System:** SmartTrack — AI-Assisted International Mobility & Foreign Travel Management System
(CSUCC OIGE Foreign Mobility Monitoring System)

**Topic:** PostgreSQL Database Security and Access Control
(Roles, Privileges, Row-Level Security, Credential Protection, and SQL Injection Prevention)

**Group members:** _\<fill in before submission\>_

**Repository artifacts used as evidence**

| Artifact | Path |
|---|---|
| GRANT/REVOKE + role script (Part C) | `database/security/01_roles_and_grants.sql` |
| RLS policy script (Part D) | `database/security/02_rls_policy.sql` |
| Safe sandbox seed records | `database/security/03_sandbox_seed.sql` |
| Allowed/blocked action tests | `database/security/04_privilege_tests.sql` |
| One-command lab runner | `database/security/run_lab_tests.ps1` |
| Actual test output (evidence) | `database/security/evidence/privilege_test_results.txt` |
| Backend credential loading (Part E) | `backend/config.py`, `backend/.env.example`, `.gitignore` |
| SQL-injection review query (Part F) | `backend/routes/auth.py` (login) |

**Safety note:** the live database `smarttrack_db` was **read-only** in this activity. All
GRANT/REVOKE, RLS, and test execution happened in the sandbox database
`smarttrack_security_lab` (schema copied from live with `pg_dump --schema-only`). The only
cluster-wide objects created are the three deliverable roles
(`smarttrack_super_admin`, `smarttrack_faculty`, `smarttrack_app`), all `NOLOGIN`.

---

## Workflow status: already implemented vs. implemented by this activity

The controls that were **already implemented** in SmartTrack were left untouched (documented
below as existing evidence); this activity only added the missing database-level controls and
fixed one credential leak found during review.

| Workflow item | Status | Where / evidence |
|---|---|---|
| 1. Identify project roles (application RBAC) | **Already implemented** — unchanged | `backend/models.py` `users.role` check (`super_admin`/`faculty`); `get_current_admin()`/`get_current_faculty()` guards on 20+ admin endpoints; JWT auth everywhere |
| 7. Store credentials safely (backend secrets) | **Already implemented** — unchanged (evidence in Part E) | `config.py` `os.getenv` + pydantic-settings `.env`; `.gitignore` lines 2–3; `.env.example` placeholders; bcrypt `gensalt(12)` password hashing |
| 8. Test allowed/blocked actions (application level) | **Already implemented** — re-executed as evidence | `tests/test_phase9_security.py` (26) + `tests/test_superadmin_guards.py` (8) → 31 passed, 2 skipped (fixture), 1 state-dependent assertion (Part C); `database/security/evidence/app_level_security_test_results.txt` |
| 2. List sensitive tables (database level) | **NEW — this activity** | Parts B & B.1 |
| 3. Create database roles | **NEW — this activity** | `database/security/01_roles_and_grants.sql` |
| 4./5. Grant only needed privileges + schema privileges | **NEW — this activity** | 7 GRANT + 5 REVOKE + `GRANT USAGE ON SCHEMA`; tests T-01…T-06 |
| 6. Design one RLS policy | **NEW — this activity** | `02_rls_policy.sql`; tests T-07…T-12 |
| Startup log printed the full `DATABASE_URL` (password included) | **FIXED this activity** | `backend/main.py` — password now masked |

---

## Part A — Identify Your System Roles

Role rule: the list matches the application roles the backend actually recognizes
(`backend/models.py`: `CheckConstraint("role IN ('super_admin','faculty')")`, enforced by
`get_current_admin()` / `get_current_faculty()` in `backend/security.py`). No invented roles.

| System role | Main responsibilities | Data/actions that require access | Security concern |
|---|---|---|---|
| **super_admin** (OIGE administrator) | Manages user accounts, verifies/rejects uploaded documents, drives the travel workflow (approve/return/remarks), monitors compliance, reads the audit trail | Full CRUD on `users`, `travels`, `documents`, `notifications`; read + append on `audit_logs` | Greatest database access: must **not** hard-delete accounts (foreign keys + history) and must **not** rewrite audit history |
| **faculty** (accountable traveler / registrar) | Registers own mobility records, uploads pre-/post-travel documents, updates own profile data, reads own notifications | Own rows in `travels`, `documents`, `notifications` | Must only ever see/edit **own** records; no access to other users' accounts, password hashes, or the audit trail |

**Role mapping to database roles (Part C):**

| Application role (`users.role`) | Database group role created | Login? |
|---|---|---|
| `super_admin` | `smarttrack_super_admin` | NO |
| `faculty` | `smarttrack_faculty` | NO |
| backend service (single shared connection) | `smarttrack_app` | NO — password set out-of-band by the DBA, stored only in `backend/.env` |

---

## Part B — Important Project Tables (5 selected)

Exact PostgreSQL names from the live schema (schema `system_core`):

| Table name | Purpose / important data | Roles that use it | Why access must be controlled |
|---|---|---|---|
| `system_core.users` | Accounts, **bcrypt password hashes**, role, `is_active` flag, college/department | super_admin (manage); faculty (own profile via backend) | Credential store — password hashes and role flags must never be readable/writable by the wrong role |
| `system_core.travels` | Core mobility records (event, dates, funding, workflow status, remarks), row owner `user_id` | super_admin (all rows); faculty (own rows) | Main transactional data of the system; contains personal/professional travel details of faculty |
| `system_core.documents` | Uploaded pre-/post-travel evidence files, verification status, rejection remarks | super_admin (verify/reject); faculty (upload own) | Uploaded documents are sensitive; verification status drives compliance decisions |
| `system_core.notifications` | Per-user messages (`user_id`, `is_read`) | super_admin (system-generated); faculty (own) | Row-owned data — faculty must not read other users' notifications |
| `system_core.audit_logs` | Security/administrative activity history (who did what, IP, user agent) | super_admin (read + append only) | Audit trail: must be append-only and hidden from non-admins, or tamper evidence is lost |

---

## Part B.1 — Access-Control Matrix

Y = granted, N = not granted, "Own rows" = table privilege plus row restriction
(RLS for `travels`; backend row filtering for `documents`/`notifications`).

| Table | Role | SELECT | INSERT | UPDATE | DELETE | Restriction / reason |
|---|---|:-:|:-:|:-:|:-:|---|
| `users` | super_admin | Y | Y | Y | **N** | Accounts are **deactivated** (`is_active = false`), never hard-deleted (FK integrity + history) |
| `users` | faculty | **N** | **N** | **N** | **N** | No direct access at all; own profile is served by the backend |
| `travels` | super_admin | Y | Y | Y | Y | Full workflow management |
| `travels` | faculty | Own rows | Own rows | Own rows | **N** | RLS policy `travels_faculty_own_rows`; `DELETE` revoked (audit-trail integrity) |
| `documents` | super_admin | Y | Y | Y | Y | Verification / rejection actions |
| `documents` | faculty | Y | Y | Y | **N** | Backend restricts to own travels (`travels.user_id` join); no delete of evidence |
| `notifications` | super_admin | Y | Y | Y | Y | System-generated notices |
| `notifications` | faculty | Own rows | Own rows | Own rows (`is_read`) | **N** | Own `user_id` only (enforced in backend; future RLS candidate) |
| `audit_logs` | super_admin | Y | Y | **N** | **N** | **Append-only**: no UPDATE/DELETE for anyone, including admin |
| `audit_logs` | faculty | **N** | **N** | **N** | **N** | Audit trail invisible to non-admins |

Resulting grants straight from the sandbox run
(`database/security/evidence/privilege_test_results.txt`, end of file):

```
        grantee         |  table_name   |           privileges
------------------------+---------------+--------------------------------
 smarttrack_faculty     | documents     | INSERT, SELECT, UPDATE
 smarttrack_faculty     | notifications | INSERT, SELECT, UPDATE
 smarttrack_faculty     | travels       | INSERT, SELECT, UPDATE
 smarttrack_super_admin | audit_logs    | INSERT, SELECT
 smarttrack_super_admin | documents     | DELETE, INSERT, SELECT, UPDATE
 smarttrack_super_admin | notifications | DELETE, INSERT, SELECT, UPDATE
 smarttrack_super_admin | travels       | DELETE, INSERT, SELECT, UPDATE
 smarttrack_super_admin | users         | INSERT, SELECT, UPDATE
```

Rows absent from the list (`smarttrack_faculty` on `users` / `audit_logs`) = zero privileges —
exactly what the matrix requires.

---

## Part C — GRANT and REVOKE Statements (project-specific)

Full script: **`database/security/01_roles_and_grants.sql`** (idempotent). Key statements:

```sql
-- Roles (NOLOGIN group roles, 1:1 with the application roles)
CREATE ROLE smarttrack_super_admin NOLOGIN;
CREATE ROLE smarttrack_faculty NOLOGIN;

-- Schema usage (Step 2)
GRANT USAGE ON SCHEMA system_core TO smarttrack_super_admin, smarttrack_faculty;

-- GRANT 1: super_admin CRUD on the five selected tables (minus Step 4 carve-outs)
GRANT SELECT, INSERT, UPDATE, DELETE
    ON system_core.users, system_core.travels, system_core.documents,
       system_core.notifications, system_core.audit_logs
    TO smarttrack_super_admin;

-- GRANT 2: faculty read access only where needed
GRANT SELECT
    ON system_core.travels, system_core.documents, system_core.notifications
    TO smarttrack_faculty;

-- GRANT 3: faculty create/modify on its working tables
GRANT INSERT, UPDATE
    ON system_core.travels, system_core.documents, system_core.notifications
    TO smarttrack_faculty;

-- GRANT 4: sequences so faculty can allocate keys for rows it inserts
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA system_core
    TO smarttrack_super_admin, smarttrack_faculty;

-- REVOKE 1: faculty can never remove mobility records
REVOKE DELETE ON system_core.travels       FROM smarttrack_faculty;
REVOKE DELETE ON system_core.documents     FROM smarttrack_faculty;
REVOKE DELETE ON system_core.notifications FROM smarttrack_faculty;

-- REVOKE 2: faculty has NO access to the user/credential table
REVOKE ALL ON system_core.users FROM smarttrack_faculty;

-- REVOKE 3: faculty cannot read/write the audit trail
REVOKE ALL ON system_core.audit_logs FROM smarttrack_faculty;

-- REVOKE 4: admin never hard-deletes accounts (deactivation instead)
REVOKE DELETE ON system_core.users FROM smarttrack_super_admin;

-- REVOKE 5: audit trail is append-only even for the admin
REVOKE UPDATE, DELETE ON system_core.audit_logs FROM smarttrack_super_admin;
```

### Test evidence — allowed vs. blocked (executed in sandbox)

Runner: `powershell -ExecutionPolicy Bypass -File database\security\run_lab_tests.ps1`
→ output: `database/security/evidence/privilege_test_results.txt`
(PostgreSQL 18.6; every test runs in its own transaction and is rolled back).

| SQL / test ID | Role + table | Privilege change or test | Actual result / interpretation | Evidence ID |
|---|---|---|---|---|
| C-1 | `smarttrack_super_admin` + `users,travels,documents,notifications,audit_logs` | GRANT SELECT/INSERT/UPDATE/DELETE, then REVOKE DELETE on `users` and UPDATE/DELETE on `audit_logs` | Grant listing shows `users = INSERT, SELECT, UPDATE` (no DELETE) and `audit_logs = INSERT, SELECT` — matches matrix | EV-C1 (evidence file, grants table) |
| C-2 | `smarttrack_faculty` + `travels,documents,notifications` | GRANT SELECT/INSERT/UPDATE, REVOKE DELETE | Grant listing: `INSERT, SELECT, UPDATE` only — no DELETE anywhere for faculty | EV-C2 (evidence file, grants table) |
| C-3 / T-01 | super_admin + `travels` | SELECT (allowed) | `count = 3` — admin sees all seeded rows | EV-C3 |
| C-4 / T-02 | super_admin + `travels` | DELETE disposable row 9103 (allowed) | `DELETE 1`, remaining `0` | EV-C4 |
| C-5 / T-03 | faculty + `travels` | DELETE (blocked) | `ERROR: permission denied for table travels` | EV-C5 |
| C-6 / T-04 | faculty + `users` | UPDATE `is_active` (blocked) | `ERROR: permission denied for table users` | EV-C6 |
| C-7 / T-05 | faculty + `users` | SELECT `password_hash` (blocked) | `ERROR: permission denied for table users` — credential hashes unreadable | EV-C7 |
| C-8 / T-06 | faculty + `audit_logs` | INSERT (blocked) | `ERROR: permission denied for table audit_logs` | EV-C8 |

All expected BLOCKED errors and expected ALLOWED results occurred exactly as designed.

### Application-level allowed/blocked tests — already implemented before this activity

SmartTrack already ships two live-API security suites. They were **re-executed** during this
activity so the evidence is fresh; neither suite was modified.

| Suite (already implemented) | What it proves | Result in this run |
|---|---|---|
| `tests/test_phase9_security.py` (26 tests) | BLOCKED without auth (401): `/me`, `/travels`, `/documents`, `/audit`, `/ai/insights`, `/compliance`; bad token & empty bearer rejected. BLOCKED for faculty (403): read `audit_logs`, list users, read all remarks, create user/announcement/doc type, recompute/list insights, list compliance records. Input validation incl. login SQL-injection payload | 24 passed; **2 skipped** — the ownership tests need an existing travel owned by another faculty account as fixture; none exists in the current dev data (pre-existing condition) |
| `tests/test_superadmin_guards.py` (8 tests) | Admin self-protection: cannot deactivate self, cannot change own role, invalid role rejected, super-admin cap respected, deactivated users logged out, updates cannot change role/active | 7 passed; **1 state-dependent assertion** (below) |
| **Run summary** | `database/security/evidence/app_level_security_test_results.txt` | **Ran 34 → 31 passed, 2 skipped, 1 failed assertion.** The failure (`test_role_change_blocks_account`) is a data-state-dependent expectation in the *pre-existing* test, not a security-control failure: with only one active `super_admin` in the dev data, re-activating the promoted account correctly returned 200 (cap = 2 active super admins), while the test — written for a database where two super admins are already active — expected 400. All deny/guard assertions before that line passed. |

---

## Part D — Row-Level Security (RLS) Decision

| Question | Project answer |
|---|---|
| Do multiple users/roles access the same table? | **Yes.** Both `super_admin` and `faculty` query `system_core.travels` (admin dashboard vs. "my mobility records"). |
| Should a user see only rows belonging to them (own office/group/tenant)? | **Yes for faculty.** Row ownership = `travels.user_id → users.user_id` ("Record owner (faculty/admin who registered the mobility)" — model comment in `backend/models.py`). |
| Which table(s) need row filtering? | `system_core.travels` (primary); `notifications` and `documents` are secondary candidates (ownership via `user_id` / parent travel). |
| Does the project need PostgreSQL RLS? | **YES** |
| Justification based on an actual feature | The **Faculty Mobility List / My Records** feature must show a faculty member only their own travels while the admin sees everything. Today that filtering exists **only in application code** (routes add `WHERE ... user_id = current_user.user_id`), so a single missed filter or injected query clause would leak every faculty member's travel data. RLS pushes the ownership rule **into the database** so it holds regardless of which query runs, under the identity the backend supplies per request. |

### Policy design (one policy, project-specific — `database/security/02_rls_policy.sql`)

| Element | Design |
|---|---|
| Protected table | `system_core.travels` |
| Row-ownership condition | `user_id = NULLIF(current_setting('app.current_user_id', true), '')::integer` |
| Permitted operations | `FOR ALL` (SELECT/INSERT/UPDATE) limited to own rows for `smarttrack_faculty`; full access for `smarttrack_super_admin` |
| Identity supplied by backend | `SET LOCAL app.current_user_id = <user_id from verified JWT>` inside the request's transaction — value comes from the authenticated token (server-side), never from SQL text supplied by the client |
| Fail-closed behavior | Unset/empty identity → `NULLIF(...) = NULL` → predicate NULL → **0 rows visible, inserts rejected** (proven by T-08) |

```sql
ALTER TABLE system_core.travels ENABLE ROW LEVEL SECURITY;

CREATE POLICY travels_admin_all ON system_core.travels
    FOR ALL TO smarttrack_super_admin
    USING (true) WITH CHECK (true);

CREATE POLICY travels_faculty_own_rows ON system_core.travels
    FOR ALL TO smarttrack_faculty
    USING (user_id = NULLIF(current_setting('app.current_user_id', true), '')::integer)
    WITH CHECK (user_id = NULLIF(current_setting('app.current_user_id', true), '')::integer);
```

### Policy test evidence (sandbox)

| Test | Expectation | Actual result | Evidence ID |
|---|---|---|---|
| T-07: faculty SELECT with identity 9001 | allowed, only own row | `count = 1` (admin row invisible) | EV-D1 |
| T-08: faculty SELECT with **no** identity | fail-closed, 0 rows | `count = 0` | EV-D2 |
| T-09: faculty INSERT row owned by itself | allowed | `INSERT 0 1` | EV-D3 |
| T-10: faculty INSERT row owned by another user | blocked | `ERROR: new row violates row-level security policy for table "travels"` | EV-D4 |
| T-11: faculty UPDATE own row | allowed | `UPDATE 1` | EV-D5 |
| T-12: faculty UPDATE another user's row | blocked by RLS | `UPDATE 0`, target row invisible | EV-D6 |

**Rollout note (why the live table is untouched):** the live backend connects as the table
owner (`postgres`), and a table owner bypasses RLS unless `FORCE ROW LEVEL SECURITY` is set.
The policy is therefore designed, executed, and proven in the sandbox first; live enablement is
a controlled follow-up: (1) backend sets `SET LOCAL app.current_user_id` on every request,
(2) run `02_rls_policy.sql` on `smarttrack_db`, (3) only then consider `FORCE ROW LEVEL SECURITY`
(and connect as `smarttrack_app` rather than the owner). Enabling RLS before step 1 would not
break the current backend — it would simply have no effect on the owner connection.

---

## Part E — Protect Database Credentials in the Backend

| Security check | Required evidence | Our evidence |
|---|---|---|
| Credentials not hard-coded in committed source | Environment-variable/config loading, secrets hidden | `backend/config.py` loads everything through `os.getenv(...)` / pydantic-settings with `env_file = ".env"`: <br> `DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://postgres@127.0.0.1:5432/smarttrack_db")` <br> `SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")` <br> Real values live only in `backend/.env` (values **not** reproduced here). |
| `.env` excluded from Git | `.gitignore` entry | `.gitignore` lines 2–3: `.env` and `backend/.env`; also `backend/logs/`, `logs/` (line 19–23) so runtime logs are never distributed. `backend/.env.example` ships only `CHANGE_ME` placeholders. |
| Repository/screenshots expose no password, token, or private connection string | Repository review + sanitized evidence | Project source contains **no** literal password/token/private connection string. Finding below was found and fixed during this activity. |
| Database account has only the privileges needed by the backend | Short explanation linked to the access-control matrix | Role `smarttrack_app` (in `01_roles_and_grants.sql`, Step 5): `SELECT, INSERT, UPDATE, DELETE` on schema `system_core` + `USAGE/SELECT` on sequences, **no** superuser/createrole/createdb, no schema DDL — the runtime union of the two matrix roles. It can also `SET ROLE` into `smarttrack_super_admin`/`smarttrack_faculty`. Activation (password set out-of-band → `backend/.env`) is a deliberate follow-up so the running system is not disturbed by this activity. |

**Summary:** credential loading (`.env` via pydantic-settings), Git exclusion (`.gitignore`
lines 2–3), secret placeholders (`.env.example`), and bcrypt password hashing were **already
implemented** before this activity and were left untouched; the only credential-related change
made here is the masked startup log line below.

**Scope note — test fixture (left unchanged by group decision):** `backend/tests/base.py`
carries default credentials for the group's **localhost-only** development test accounts used
by the live-API test suites (seeded admin/faculty fixture users). These are test fixtures, not
application or database credentials. All real secrets (database URL, JWT signing key) remain
only in the gitignored `backend/.env`, and no secret value appears in this report or in the
committed evidence files (verified by a secret-pattern scan: 0 hits).

**Finding found & fixed (was: password written to the startup log):**

```python
# BEFORE (backend/main.py) — logged the full connection string, password included:
logger.info(f"Database: {settings.DATABASE_URL}")

# AFTER — same line, password masked:
_db = urlparse(settings.DATABASE_URL)
logger.info(f"Database: {_db.scheme}://{_db.username + ':' if _db.username else ''}****@{_db.hostname}:{_db.port or '?'}{_db.path}")
```

Older local log files (gitignored, never committed) still contain the previous output; rotating
or deleting `backend/logs/` is recommended after the fix deploys.

---

## Part F — Review One Project Query for SQL Injection Protection

| Review item | Group response |
|---|---|
| Feature / file / function reviewed | **Login** — `backend/routes/auth.py`, `login()` |
| User input involved | `request.email` (and `request.password`) from the untrusted JSON request body |
| SQL / ORM statement used | `user = db.query(User).filter(User.email == request.email).first()` → SQLAlchemy compiles it to `SELECT ... FROM system_core.users WHERE system_core.users.email = %(email)s` |
| Parameterized query / ORM binding used? | **YES** |
| Why the statement avoids SQL injection (or correction made) | The email value is passed to the driver as a **bind parameter**, separately from the SQL template: PostgreSQL receives a prepared statement plus data — the data is never re-parsed as SQL syntax. An input like `' OR '1'='1` is just an email **value** that matches no row (`count 0` → generic "Invalid email or password"), and the password is then checked in Python with `bcrypt.checkpw()` against the stored hash (`security.py`), never inside SQL. A repository-wide search found **zero** f-string/`format()`-built SQL statements in project backend code — all DB access goes through the ORM with bound parameters. |

Unsafe pattern (for comparison only, not present in this project):

```python
# UNSAFE — never used in this codebase
query = f"SELECT * FROM system_core.users WHERE email = '{email}'"
```

**Already-implemented regression test for this exact concern (re-run this activity: PASSED):**
`tests/test_phase9_security.py::test_login_sql_injection_safe` posts the payload
`oige@csucc.edu.ph'; DROP TABLE users;--` and asserts 401/422 plus a healthy server
afterwards — result in this run: `ok`
(`database/security/evidence/app_level_security_test_results.txt`).

---

## Required Evidence Checklist (activity item 10)

| Required evidence | Where it is |
|---|---|
| System roles + 3–5 important tables, actual project names | Parts A & B (from `models.py` / live schema) |
| Access-control matrix for selected tables and actual roles | Part B.1 (+ grant listing EV-C1/C2) |
| Project-specific GRANT/REVOKE SQL and execution/test results | `01_roles_and_grants.sql`, Part C, evidence file |
| RLS decision with project-specific justification (+ policy design/testing) | Part D, `02_rls_policy.sql`, tests T-07…T-12 |
| Backend credential-protection evidence, secrets hidden | Part E (`config.py`, `.env.example`, `.gitignore`, redacted log line) |
| One actual project query with SQL-injection explanation | Part F (`routes/auth.py` login) + already-implemented `test_login_sql_injection_safe` (re-run, passed) |
| Application-level allowed/blocked tests (already implemented, re-executed) | `database/security/evidence/app_level_security_test_results.txt` (34 tests: 31 passed, 2 skipped on missing fixture, 1 state-dependent assertion explained in Part C) |
| Repository checkpoint matching the demonstrated work | Files listed at the top of this report |

## How to reproduce (for the demo)

```powershell
# 1. Builds sandbox smarttrack_security_lab (live DB read-only),
#    applies roles/GRANTs + RLS, seeds safe test rows, runs all 12 tests,
#    and rewrites the evidence file:
powershell -ExecutionPolicy Bypass -File database\security\run_lab_tests.ps1

# 2. Show the result:
notepad database\security\evidence\privilege_test_results.txt
```

---

## Post-Laboratory Reflection

1. **Which project role currently has the greatest database access, and is every privilege necessary?**
   `super_admin` — via `smarttrack_super_admin` it holds CRUD on the five selected tables.
   Two privileges were deliberately removed even for this role: `DELETE` on `users`
   (accounts are deactivated, not deleted, to preserve foreign keys and history) and
   `UPDATE/DELETE` on `audit_logs` (append-only trail). Its `audit_logs` access itself was cut
   down to `SELECT, INSERT`.

2. **Which selected table contains the most sensitive or critical data, and how is access restricted?**
   `system_core.users` — it stores bcrypt password hashes and role flags. Faculty has **zero**
   privileges on it (`REVOKE ALL`, proven by T-04/T-05: `permission denied`), the admin cannot
   hard-delete rows (`REVOKE DELETE`), and hashes are never returned by the API.

3. **Why did the group decide to use or not use Row-Level Security?**
   **Use (YES).** Both roles read the same `travels` table while faculty must only see their own
   records; today that rule lives only in application code. RLS enforces ownership in the
   database itself, fail-closed when the backend supplies no identity (T-08), and the design
   matches our identity model (JWT-derived `SET LOCAL app.current_user_id` per request).

4. **What would happen if the backend database credentials were committed publicly, and what control prevents that?**
   Anyone with the credentials could read or destroy every mobility record and audit trail —
   and with the previous superuser-style account, alter the schema as well. Prevention:
   credentials live only in `backend/.env`, which `.gitignore` excludes (lines 2–3); the
   committed `.env.example` carries `CHANGE_ME` placeholders only; the startup log line that
   used to print the connection string was masked in Part E; and the least-privilege
   `smarttrack_app` role limits the blast radius of any leak.

5. **Which project query did you review for SQL injection, and what mechanism keeps user input separate from SQL syntax?**
   The **login** query `db.query(User).filter(User.email == request.email)` in
   `backend/routes/auth.py`. SQLAlchemy sends it as a parameterized statement
   (`WHERE system_core.users.email = %(email)s`); the database parses/executes the SQL template
   and compares the separately-bound value, so user input can never change the statement's
   syntax — a classic `' OR '1'='1` payload is only ever data.
