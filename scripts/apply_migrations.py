"""
Apply database/migration_*.sql in numeric order, tracking applied versions
in system_core.schema_migrations. Idempotent — re-running only applies new files.

Usage (from backend/ with the venv python):
    python ../scripts/apply_migrations.py
    python ../scripts/apply_migrations.py --dry-run
"""
import argparse
import glob
import os
import re
import sys
from datetime import datetime, timezone

import psycopg2
from psycopg2 import sql as pg_sql

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRATIONS_DIR = os.path.join(REPO_ROOT, "database")

# Credentials live in backend/.env (see backend/.env.example). Fall back to a
# repo-root .env for deployments that keep it there.
ENV_PATH = next(
    (p for p in (
        os.path.join(REPO_ROOT, "backend", ".env"),
        os.path.join(REPO_ROOT, ".env"),
    ) if os.path.exists(p)),
    os.path.join(REPO_ROOT, "backend", ".env"),
)


def load_env(path: str) -> dict:
    env = {}
    if not os.path.exists(path):
        return env
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def db_params(env: dict) -> dict:
    url = env.get("DATABASE_URL", "")
    # postgresql://user:pass@host:port/db
    m = re.match(r"postgresql://([^:@/]+)(?::([^@/]*))?@([^:/]+):(\d+)/(\w+)", url)
    if m:
        return {
            "user": m.group(1),
            "password": m.group(2) or "",
            "host": m.group(3),
            "port": m.group(4),
            "dbname": m.group(5),
        }
    return {
        "user": env.get("POSTGRES_USER", "postgres"),
        "password": env.get("POSTGRES_PASSWORD", ""),
        "host": env.get("POSTGRES_HOST", "127.0.0.1"),
        "port": env.get("POSTGRES_PORT", "5432"),
        "dbname": env.get("POSTGRES_DB", "smarttrack_db"),
    }


def migration_files() -> list:
    files = sorted(glob.glob(os.path.join(MIGRATIONS_DIR, "migration_*.sql")))
    return files


def ensure_tracking_table(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS system_core")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS system_core.schema_migrations (
                version    TEXT PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
        """)
    conn.commit()


def applied_versions(conn) -> set:
    with conn.cursor() as cur:
        cur.execute("SELECT version FROM system_core.schema_migrations")
        return {row[0] for row in cur.fetchall()}


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply SmartTrack SQL migrations in order")
    parser.add_argument("--dry-run", action="store_true", help="list what would run, change nothing")
    parser.add_argument("--baseline", action="store_true",
                        help="mark all migrations as applied WITHOUT running them "
                             "(for databases already at head from manual applies)")
    args = parser.parse_args()

    env = load_env(ENV_PATH)
    params = db_params(env)
    files = migration_files()
    if not files:
        print("No migration files found in", MIGRATIONS_DIR)
        return 1

    try:
        conn = psycopg2.connect(**params)
    except Exception as e:
        print(f"ERROR: cannot connect to database: {e}")
        return 1

    try:
        ensure_tracking_table(conn)
        done = applied_versions(conn)
        pending = [f for f in files if os.path.basename(f) not in done]

        if args.baseline:
            if not pending:
                print("Nothing to baseline — all migrations already recorded.")
                return 0
            print(f"Baselining {len(pending)} migration(s) as applied (no DDL executed)...")
            with conn.cursor() as cur:
                for path in pending:
                    cur.execute(
                        "INSERT INTO system_core.schema_migrations (version) VALUES (%s) "
                        "ON CONFLICT (version) DO NOTHING",
                        (os.path.basename(path),),
                    )
            conn.commit()
            print("Baseline complete. Future runs will only apply new migrations.")
            return 0

        print(f"Found {len(files)} migration file(s); {len(done)} already applied; {len(pending)} pending.")
        if not pending:
            print("Database is up to date.")
            return 0

        for path in pending:
            name = os.path.basename(path)
            if args.dry_run:
                print(f"  DRY-RUN would apply: {name}")
                continue
            print(f"Applying {name} ...", end=" ")
            with open(path, encoding="utf-8") as f:
                ddl = f.read()
            try:
                with conn.cursor() as cur:
                    cur.execute(ddl)
                    cur.execute(
                        "INSERT INTO system_core.schema_migrations (version) VALUES (%s) "
                        "ON CONFLICT (version) DO NOTHING",
                        (name,),
                    )
                conn.commit()
                print("OK")
            except Exception as e:
                conn.rollback()
                print(f"FAILED: {e}")
                print("If this database was already migrated manually, run with --baseline.")
                return 1
        if not args.dry_run:
            print("All pending migrations applied.")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
