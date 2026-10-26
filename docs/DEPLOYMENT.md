# SmartTrack — Deployment Runbook (Phase 10)

## Architecture

| Tier | Technology | Port / path |
|------|------------|-------------|
| Web UI | Flutter web static build (`flutter-web/`) | web server, e.g. `http://server/SmartTrack/` |
| API | FastAPI + uvicorn | `5000` (`/api/*`, docs at `/api/docs`) |
| Database | PostgreSQL, schema `system_core` | `5432`, db `smarttrack_db` |
| Files | Uploaded documents | `backend/uploads/` |
| Logs | Rotating file + console | `backend/logs/smarttrack.log` |

## 1. Server prerequisites

- Python 3.11+ (tested on 3.14)
- PostgreSQL 14+ (tested on 18)
- Flutter SDK 3.x (only needed to rebuild the web UI)
- A web server capable of serving static SPA files (Apache/XAMPP, nginx, IIS)
- Optional: a reverse proxy (nginx/Apache) in front of the API for TLS

## 2. First-time setup

```powershell
# Clone/copy the repo to the server, then:
Copy-Item backend\.env.example backend\.env
# Edit backend\.env:
#   DATABASE_URL  — real credentials
#   SECRET_KEY    — python -c "import secrets; print(secrets.token_urlsafe(64))"
#   DEBUG         — false for production
#   CORS_ORIGINS  — JSON array, e.g. ["https://smarttrack.csucc.edu.ph"]

.\scripts\deploy.ps1
```

`deploy.ps1` creates/updates the venv, installs `backend/requirements.txt`
(which mirrors the verified-working environment), applies SQL migrations, and
builds + syncs the Flutter web app into `flutter-web/`.

## 3. Database migrations

Migrations live in `database/migration_NNN_*.sql` and are applied **in numeric
order**, tracked in `system_core.schema_migrations`:

```powershell
backend\venv\Scripts\python scripts\apply_migrations.py           # apply pending
backend\venv\Scripts\python scripts\apply_migrations.py --dry-run # show pending only
```

The script is idempotent; safe to include in every deploy. On a brand-new
database it creates schema `system_core` and applies all twelve migrations.

**Existing databases** that were migrated manually (pre-tracking) should be
baselined once so future deploys only apply *new* files:

```powershell
backend\venv\Scripts\python scripts\apply_migrations.py --baseline
```

(For a fresh install you may instead restore `database/smarttrack_db_polished.sql`
and then run `--baseline`.)

## 4. Running the API

Development:

```powershell
cd backend
venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 5000 --reload
```

Production:

```powershell
cd backend
venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 5000 --workers 4
```

- Startup logs an explicit warning if `SECRET_KEY` is still the insecure default.
- Health check: `GET http://<server>:5000/api/health` → `{"status":"healthy",...}`.
- Keep `backend/uploads/` and `backend/logs/` on durable storage and back them up
  (see BACKUP_RECOVERY.md).

Optional Windows service via [NSSM](https://nssm.cc):

```powershell
nssm install SmartTrackAPI "C:\path\to\backend\venv\Scripts\python.exe" ^
  "-m" "uvicorn" "main:app" "--host" "0.0.0.0" "--port" "5000" "--workers" "4"
nssm set SmartTrackAPI AppDirectory "C:\path\to\backend"
nssm start SmartTrackAPI
```

## 5. Serving the web UI

Point the web server document root (or a `/SmartTrack/` alias) at the repo root;
`index.html` redirects to `flutter-web/index.html`. SPA fallback: any unknown
path under `flutter-web/` should serve `flutter-web/index.html` (an Apache
`.htaccess` is included in that folder).

To refresh the UI after code changes:

```powershell
.\scripts\sync_flutter_web.ps1           # flutter build web --release + robocopy /MIR
.\scripts\sync_flutter_web.ps1 -SkipBuild  # just copy an existing build
```

## 6. Reverse proxy / TLS (example nginx)

```nginx
server {
    listen 443 ssl;
    server_name smarttrack.csucc.edu.ph;
    # ssl_certificate ...; ssl_certificate_key ...;

    location /SmartTrack/ {
        alias /var/www/smarttrack/flutter-web/;
        try_files $uri $uri/ /SmartTrack/index.html;
    }
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        client_max_body_size 50M;   # match MAX_UPLOAD_SIZE
    }
}
```

Add the public origin to `CORS_ORIGINS` in `backend/.env` (JSON array).

## 7. Production checklist

- [ ] `backend/.env` present; **no** default `SECRET_KEY`; `DEBUG=false`
- [ ] `CORS_ORIGINS` lists only real origins (no `*`, no stray localhost in prod)
- [ ] PostgreSQL credentials are least-privilege; DB not exposed publicly
- [ ] HTTPS enabled at the proxy; HTTP redirected
- [ ] `backend/uploads/` permissions restricted; backed up (Phase-2 files are PII)
- [ ] Scheduled `scripts\backup_db.ps1` (Task Scheduler weekly + pre-upgrade)
- [ ] Log rotation verified (`logs/smarttrack.log`, 10 MB × 5)
- [ ] `/api/health` monitored
- [ ] Default seed passwords changed (see ADMIN_TRAINING.md § Account security)
- [ ] Smoke test: login as admin + faculty, upload one document, run AI Check,
      open AI Analysis → Insights, confirm audit log entry appears
- [ ] API suite run against the deployed instance:
      `python -m unittest discover -s tests -t . -v` (point `SMARTTRACK_API` at prod)

## 8. Upgrades

1. Schedule a maintenance window; run `scripts\backup_db.ps1` first.
2. Pull new code; review `database/` for new migrations.
3. `.\scripts\deploy.ps1` (applies only pending migrations, rebuilds UI).
4. Restart the API process/service.
5. Re-run the smoke test + `/api/health`.

## 9. Troubleshooting

| Symptom | Check |
|---------|-------|
| API 500s on travel/document writes | `backend/logs/smarttrack.log`; DB connectivity in `.env` |
| Login 401 for known-good users | `SECRET_KEY` changed between restarts (tokens invalidated) — re-login |
| CORS errors in browser | `CORS_ORIGINS` must include the exact scheme+host+port of the UI |
| Uploads fail >50 MB | `MAX_UPLOAD_SIZE` in `.env` **and** proxy `client_max_body_size` |
| UI loads but API calls fail | API not running on 5000, or proxy `/api/` not configured |
| Blank Flutter page | Stale `flutter-web/`; re-run `sync_flutter_web.ps1` |
