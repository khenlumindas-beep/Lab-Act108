# SmartTrack — Backup & Recovery (Phase 10)

## What must be backed up

| Asset | Location | Criticality |
|-------|----------|-------------|
| PostgreSQL database | `smarttrack_db` (schema `system_core`) | **Critical** — travels, users, compliance, audit, AI rows |
| Uploaded documents | `backend/uploads/` | **Critical** — PDFs/images are official records |
| Configuration | `backend/.env` | High — store separately/secretly, never in the SQL dump |
| Application code + `flutter-web/` | repo | Medium — rebuildable, but pin releases |
| Logs | `backend/logs/` | Low — rotate; keep ~30 days if needed for audit |

The SQL dump contains user PII and document metadata; treat backups with the
same care as the live system.

## Database backup (pg_dump)

Script: `scripts/backup_db.ps1` (reads connection from `backend/.env`).

```powershell
.\scripts\backup_db.ps1                          # default: pg_dump on PATH, keep 30
.\scripts\backup_db.ps1 -Keep 60                 # keep 60 most recent
.\scripts\backup_db.ps1 -PgDump "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
```

Output: `backups\smarttrack_YYYYMMDD_HHMMSS.sql` (plain SQL, `--no-owner
--no-privileges`). The script automatically prunes backups beyond `-Keep`.

### Schedule (Windows Task Scheduler)

```powershell
# Daily at 02:00, keep 30 days
schtasks /Create /TN "SmartTrack-Backup" /SC DAILY /ST 02:00 /TR "powershell -ExecutionPolicy Bypass -File C:\path\to\SmartTrack\scripts\backup_db.ps1"
```

Copy `backups\` off-server (NAS/object storage) on a schedule; keep at least one
off-machine copy. Suggested retention: daily 30d, weekly 12w, monthly 12m.

### Document uploads

```powershell
# Include uploads in the off-server copy (robocopy example)
robocopy C:\path\to\SmartTrack\backend\uploads X:\backups\smarttrack-uploads /MIR /Z /R:3
```

## Recovery

### Restore the database

```powershell
# 1. Stop the API first.
# 2. Restore (as a superuser). Drop+recreate if the DB is polluted:
psql -U postgres -c "DROP DATABASE IF EXISTS smarttrack_db;"
psql -U postgres -c "CREATE DATABASE smarttrack_db;"
psql -U postgres -d smarttrack_db -f backups\smarttrack_YYYYMMDD_HHMMSS.sql
```

If the dump was taken from a server where the `system_core` schema was owned by
another role, after restore run:

```sql
GRANT ALL ON SCHEMA system_core TO <app_user>;
GRANT ALL ON ALL TABLES IN SCHEMA system_core TO <app_user>;
GRANT ALL ON ALL SEQUENCES IN SCHEMA system_core TO <app_user>;
```

Then start the API and hit `/api/health`.

### Restore uploads

```powershell
robocopy X:\backups\smarttrack-uploads C:\path\to\SmartTrack\backend\uploads /MIR
```

### Point-in-time notes

Plain `pg_dump` is **not** point-in-time. If the DB runs with
`wal_level=replica`, additionally configure continuous archiving (see PostgreSQL
docs) for PITR; the dump remains the simple, verified path for this system.

## Verification (do this quarterly)

1. Restore the latest dump into a **scratch database** (e.g. `smarttrack_dr_test`).
2. Point a staging `.env` at it; start the API; log in as admin.
3. Confirm: user count, one travel with documents, one audit-log page,
   `/api/ai/insights` returns 200.
4. Confirm uploaded files still resolve (document download returns 200).
5. Record the drill date and result in your ops log.

## Disaster-recovery minimum RPO/RTO (suggested)

| Metric | Target with daily dump + daily uploads copy |
|--------|-----------------------------------------------|
| RPO (data loss) | ≤ 24 hours |
| RTO (time to restore) | ≤ 2 hours (restore dump + uploads, start API, smoke test) |
