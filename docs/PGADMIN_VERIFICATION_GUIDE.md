# pgAdmin 4 — Screenshot Guide for IT108 Activity 7

Companion to `docs/IT108_Activity_7_SmartTrack_COMPLETED.docx` (Appendix A).
Use this to capture the screenshots that prove the database-security setup exists in the
running PostgreSQL cluster.

**Golden rule:** every write operation in this guide happens in the sandbox database
`smarttrack_security_lab`. The live database `smarttrack_db` is only ever **viewed**.

Suggested screenshot folder: `database/security/evidence/pgadmin/`
Suggested naming: `pgadmin_01_servers.png`, `pgadmin_02_databases.png`, … (see each step).

---

## 0. Before you start

| Check | How |
|---|---|
| PostgreSQL is running on 5432 | pgAdmin connects, or `Get-NetTCPConnection -LocalPort 5432 -State Listen` |
| Server registered | Left tree → **Servers** → **SmartTrack** (`127.0.0.1:5432`) |
| Right database selected | `smarttrack_db` = view only · `smarttrack_security_lab` = sandbox (writes OK) |

> If pgAdmin asks for the `postgres` password, type it — **never** paste it into a screenshot.
> Blur or crop the connection dialog before saving the image.

---

## 1. Server + databases — `pgadmin_01_servers.png`

**Path:** left tree → **Servers** → **SmartTrack (127.0.0.1:5432)** → **Databases**

**What you should see:**

```
Servers
└── SmartTrack (127.0.0.1:5432)
    └── Databases
        ├── cbr_risk_mapper
        ├── postgres
        ├── smarttrack_db            <- live, untouched
        ├── smarttrack_security_lab  <- Activity 7 sandbox
        └── template1
```

**Capture:** the expanded tree showing both `smarttrack_db` and `smarttrack_security_lab`.
**Supports:** Part D (sandbox isolation), safety note.

---

## 2. The three database roles — `pgadmin_02_roles.png`

**Path:** **Servers → SmartTrack → Login/Group Roles**

**What you should see:**

| Role | Can login? | Superuser | Create DB |
|---|---|---|---|
| `smarttrack_app` | No | No | No |
| `smarttrack_faculty` | No | No | No |
| `smarttrack_super_admin` | No | No | No |

**Capture:** the expanded **Login/Group Roles** list with the three names visible.
**Supports:** Part C / workflow step 3 (create database roles), least-privilege claim.

---

## 3. One role's definition — `pgadmin_03_role_properties.png`

**Path:** right-click **`smarttrack_faculty`** → **Properties…** → **Definition** tab

**What to show:** *Can login?* **No**, *Superuser?* **No**, *Create databases?* **No**,
*Create roles?* **No**.

**Capture:** the Definition tab (role name visible in the dialog title).
**Supports:** Part C — roles exist but cannot be used to log in (no standing credentials).

---

## 4. The five selected tables — `pgadmin_04_tables.png`

**Path:** **Databases → smarttrack_db → Schemas → system_core → Tables**

**What you should see (the five selected in Part B):**

`users` · `travels` · `documents` · `notifications` · `audit_logs`

**Capture:** the Tables list in schema `system_core`, with the five names legible.
**Supports:** Part B (table inventory, real project names).

---

## 5. Table privileges (GRANT/REVOKE result) — `pgadmin_05_table_privileges.png`

**Path:** right-click **`users`** → **Properties…** → **Security** tab

**What to show:**

- `smarttrack_super_admin` → `SELECT`, `INSERT`, `UPDATE` (no `DELETE`)
- `smarttrack_faculty` → **no entry** (all privileges revoked)
- `smarttrack_app` → runtime union of the two roles

Repeat for `travels` if you want a second screenshot (`pgadmin_05b_travels_privileges.png`).

**Capture:** the Security tab grantee grid for `users`.
**Supports:** Part B.1 (access-control matrix) and Part C (REVOKE ALL on `users` for faculty).

> If the Security tab looks empty, click the **SQL** tab of the same dialog and capture the
> generated `GRANT`/`REVOKE` statements instead — that is equally valid evidence.

---

## 6. Schema privileges — `pgadmin_06_schema_privileges.png`

**Path:** **Databases → smarttrack_db → Schemas** → right-click **`system_core`** →
**Properties…** → **Security** tab

**What to show:** `USAGE` granted to `smarttrack_super_admin`, `smarttrack_faculty`,
`smarttrack_app` (no `CREATE`).

**Capture:** the schema Security tab.
**Supports:** Part C / workflow step 5 (apply schema privileges).

---

## 7. RLS is OFF on the live table — `pgadmin_07_rls_live_off.png`

**Path:** `smarttrack_db → Schemas → system_core → Tables` → right-click **`travels`** →
**Properties…** → **Security** tab (row-security checkboxes)

**What to show:** row-level security **not** enabled, and the **Policies** node under
`travels` empty.

**Capture:** this dialog (or the Query Tool result below).
**Supports:** the safety claim "live database untouched".

Query Tool alternative (read-only, safe on the live DB):

```sql
SELECT relrowsecurity AS rls_enabled, relforcerowsecurity AS rls_forced
FROM   pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE  n.nspname = 'system_core' AND c.relname = 'travels';
-- expected on smarttrack_db: rls_enabled = false
```

---

## 8. RLS is ON in the sandbox — `pgadmin_08_rls_sandbox_on.png`

**Path:** `smarttrack_security_lab → Schemas → system_core → Tables` → **`travels`** →
**Properties…** → **Security** tab

**What to show:** row-level security **enabled**.

Query Tool alternative (run **in the sandbox**):

```sql
SELECT relrowsecurity AS rls_enabled FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'system_core' AND c.relname = 'travels';
-- expected on smarttrack_security_lab: rls_enabled = true
```

**Capture:** the dialog or the query result grid.
**Supports:** Part D (policy applied and tested in the sandbox).

---

## 9. The two policies — `pgadmin_09_policies.png`

**Path:** `smarttrack_security_lab → … → Tables → travels` → expand **Policies**

**What you should see:**

| Policy | Applies to | USING expression |
|---|---|---|
| `travels_faculty_own_rows` | `smarttrack_faculty` (SELECT/ALL) | `user_id = NULLIF(current_setting('app.current_user_id', true), '')::int` |
| `travels_admin_all` | `smarttrack_super_admin` | `true` |

Right-click a policy → **Properties…** → **Expression** tab to show the `USING` clause.

**Capture:** the Policies list, plus optionally the expression tab
(`pgadmin_09b_policy_expression.png`).
**Supports:** Part D (policy design), workflow step 6.

---

## 10. Allowed vs blocked at the DB level — `pgadmin_10_rls_test.png`

**Path:** **Query Tool** opened on `smarttrack_security_lab` (never on `smarttrack_db`).

```sql
-- identity supplied by the backend per request (JWT -> SET LOCAL)
SET LOCAL app.current_user_id = '3';
SET ROLE smarttrack_faculty;
SELECT travel_id, user_id FROM system_core.travels;   -- ALLOWED: own rows only
RESET ROLE;

-- fail-closed: no identity supplied
SET LOCAL app.current_user_id = '';
SET ROLE smarttrack_faculty;
SELECT count(*) FROM system_core.travels;             -- BLOCKED: 0 rows

-- faculty touching another user's data
RESET ROLE;
SET ROLE smarttrack_faculty;
DELETE FROM system_core.travels WHERE user_id = 1;    -- BLOCKED: permission denied
```

**Capture:** the Messages/Data Output pane showing the rows returned and the
`ERROR: permission denied` line.
**Supports:** Part C test evidence + Part D (tests T-07…T-12).

> The same 12 checks run unattended with
> `powershell -ExecutionPolicy Bypass -File database\security\run_lab_tests.ps1`
> (evidence: `database/security/evidence/privilege_test_results.txt`).

---

## 11. Credentials are NOT in pgAdmin — `pgadmin_11_env_example.png`

Workflow step 7 is a **backend** concern, so there is nothing to click in pgAdmin. Capture
instead:

1. `backend/.env.example` — shows `CHANGE_ME` placeholders only.
2. `.gitignore` lines 2–3 — `.env` and `backend/.env` excluded.
3. `backend/main.py` startup log line — password masked as `postgres:****@`.

**Capture:** those three snippets in your editor (never the real `backend/.env`).
**Supports:** Part E.

---

## Checklist before submitting

| # | Screenshot | Captured? | Used in |
|---|---|---|---|
| 1 | `pgadmin_01_servers.png` | ☐ | Safety note / Part D |
| 2 | `pgadmin_02_roles.png` | ☐ | Part C |
| 3 | `pgadmin_03_role_properties.png` | ☐ | Part C |
| 4 | `pgadmin_04_tables.png` | ☐ | Part B |
| 5 | `pgadmin_05_table_privileges.png` | ☐ | Part B.1 / Part C |
| 6 | `pgadmin_06_schema_privileges.png` | ☐ | Part C |
| 7 | `pgadmin_07_rls_live_off.png` | ☐ | Safety note |
| 8 | `pgadmin_08_rls_sandbox_on.png` | ☐ | Part D |
| 9 | `pgadmin_09_policies.png` | ☐ | Part D |
| 10 | `pgadmin_10_rls_test.png` | ☐ | Part C / Part D |
| 11 | `pgadmin_11_env_example.png` | ☐ | Part E |

**Screenshot hygiene:** crop the pgAdmin toolbar/connection dialog, hide the password field,
and make sure no `.env` value, token, or password is visible in any image.
