# SmartTrack — AI-Assisted International Mobility & Foreign Travel Management System

CSUCC OIGE system for monitoring faculty/staff international mobility and foreign
travel: pre-travel requirements, document verification, compliance (BR-07),
post-travel and re-entry tracking, notifications, audit trail, and
heuristics-based AI document/monitoring services (FR-AI01–AI06).

**Canonical UI:** Flutter web (`mobile_app/`, served from `flutter-web/`).
The legacy HTML client in `frontend/` is retired and kept only for e2e regression
scripts. Root `index.html` redirects to the Flutter app.

## Repository layout

| Path | Purpose |
|------|---------|
| `backend/` | FastAPI app (port 5000), venv, `.env`, uploads, logs |
| `backend/tests/` | Phase 9 suite (unittest, live-API) |
| `backend/ai_engine.py` / `ai_monitor.py` | AI document services + monitoring |
| `mobile_app/` | Flutter source (canonical) |
| `flutter-web/` | Deployed Flutter web build (synced from `mobile_app/build/web`) |
| `frontend/` | Retired legacy HTML UI (e2e only) |
| `database/` | Ordered SQL migrations `migration_001..012` (+ dumps) |
| `scripts/` | Deploy, migrations, backup, Flutter sync |
| `docs/` | Deployment, backup, admin training, faculty orientation |
| `tests/e2e/` | Playwright regression scripts (admin 41 checks, faculty 24) |

## Quick start (development)

Prereqs: Python 3.11+, PostgreSQL 14+, Flutter 3.x, XAMPP or any static server.

```powershell
# 1. Backend
cd backend
python -m venv venv
venv\Scripts\pip install -r requirements.txt
copy .env.example .env   # then edit: DATABASE_URL, SECRET_KEY, DEBUG=true
python ..\scripts\apply_migrations.py
python -m uvicorn main:app --host 127.0.0.1 --port 5000
# API: http://127.0.0.1:5000/api/docs   Health: /api/health

# 2. Flutter web (dev server)
cd ..\mobile_app
flutter run -d chrome --web-port 8080
# or build+sync for the XAMPP-served app:
..\scripts\sync_flutter_web.ps1
```

Default accounts (change passwords before real use):
- Admin: `oige@csucc.edu.ph` / `AdminPass123!`
- Faculty: `jpayla@csucc.edu.ph` / `FacultyPass123!`

## One-shot deploy

```powershell
.\scripts\deploy.ps1                 # venv + requirements + migrations + flutter build/sync
.\scripts\deploy.ps1 -SkipFlutter    # backend-only
```

Production start (behind your web server / reverse proxy):

```powershell
cd backend
venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 5000 --workers 4
```

Set `DEBUG=false` and a strong `SECRET_KEY` in `backend/.env` (see
`backend/.env.example`). Full runbook: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Database

- Schema `system_core`; apply migrations in order via
  `python scripts/apply_migrations.py` (tracked in `system_core.schema_migrations`).
- Backups: `scripts\backup_db.ps1` → `backups\smarttrack_<timestamp>.sql`
  (see [docs/BACKUP_RECOVERY.md](docs/BACKUP_RECOVERY.md)).

## Testing

```powershell
# API suite (server must be running on :5000)
cd backend
venv\Scripts\python -m unittest discover -s tests -t . -v

# UI regressions (legacy frontend + Playwright/Edge)
node tests\e2e\admin_e2e.js        # 41 checks
node tests\e2e\fac_features_test.js # 24 checks

# Flutter
cd mobile_app; flutter test
```

## Training materials

- Administrators: [docs/ADMIN_TRAINING.md](docs/ADMIN_TRAINING.md)
- Faculty / end users: [docs/FACULTY_ORIENTATION.md](docs/FACULTY_ORIENTATION.md)

## Scope notes

- AI is **heuristics + rules only** (no OCR/LLM). FR-F11 (AI assistant chat) is
  deferred by project decision.
- PDF/Excel exports and compliance engine (BR-07) are in scope and implemented.

## Course submissions

- **Lab-Act108** — IT108 Activity 7: PostgreSQL Database Security and Access
  Control. Deliverables: `docs/IT108_Activity_7_SmartTrack_COMPLETED.docx`
  (lab report), `docs/IT108_ACTIVITY7_DATABASE_SECURITY.md` (repository
  evidence), and `database/security/` (roles, GRANT/REVOKE, RLS policy,
  sandbox test scripts + evidence).
