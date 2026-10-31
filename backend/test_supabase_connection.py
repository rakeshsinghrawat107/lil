import os
import sys
from pathlib import Path

# Ensure root dir is in path
root_dir = Path(__file__).resolve().parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from backend.app.config import Config
from backend.app.db.connection import get_connection, is_postgres, fetch_one, fetch_all, run_migrations
from backend.app.db.seed import seed_database

def check_supabase():
    url = os.environ.get("DATABASE_URL") or Config.DATABASE_URL
    print("=" * 60)
    print("TAPMI Cultural Committee - Supabase Connection Diagnostic")
    print("=" * 60)

    masked_url = url
    if "@" in url:
        prefix, host_part = url.split("@", 1)
        scheme_user = prefix.split(":")[0] + "://***:***"
        masked_url = f"{scheme_user}@{host_part}"

    print(f"Target Database URL: {masked_url}")

    if not (url.startswith("postgres://") or url.startswith("postgresql://")):
        print("\n[INFO] Currently configured for local SQLite.")
        print("To connect to Supabase, update DATABASE_URL in your .env file with your Supabase PostgreSQL connection string.")
        print("\nExample (Supabase Transaction Pooler, Recommended):")
        print("  DATABASE_URL=postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=require")
        print("\nExample (Direct Supabase connection):")
        print("  DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres?sslmode=require")
        return False

    print("\n[1/4] Attempting connection to Supabase PostgreSQL...")
    try:
        conn = get_connection()
        print(" -> Connection successful!")
    except Exception as e:
        print(f" [ERROR] Could not connect to Supabase: {e}")
        print("\nTroubleshooting tips:")
        print("  1. Verify the password in your connection string.")
        print("  2. Ensure IP restrictions / firewall are not blocking port 6543 or 5432.")
        print("  3. For pooler connection, ensure port 6543 (transaction) or 5432 (session) is used.")
        print("  4. Check if password special characters need URL-encoding (e.g. '@' -> '%40').")
        return False

    try:
        print("\n[2/4] Verifying PostgreSQL database version...")
        version_row = fetch_one(conn, "SELECT version();")
        if version_row:
            v_text = list(version_row.values())[0]
            print(f" -> PostgreSQL Version: {v_text.splitlines()[0]}")

        print("\n[3/4] Checking existing tables...")
        tables = fetch_all(conn, """
            SELECT tablename 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            ORDER BY tablename;
        """)
        table_names = [t["tablename"] for t in tables]
        print(f" -> Found {len(table_names)} tables in 'public' schema.")
        if table_names:
            print(f"    Tables: {', '.join(table_names[:8])}{'...' if len(table_names) > 8 else ''}")

        if len(table_names) < 15:
            print("\n[4/4] Applying migrations and seeding database...")
            conn.close()
            run_migrations()
            seed_database()
            print(" -> Migrations and seeding completed successfully!")
        else:
            print("\n[4/4] Tables are already present and ready.")
            conn.close()

        print("\n" + "=" * 60)
        print("SUCCESS: Supabase is fully configured and ready for application traffic!")
        print("=" * 60)
        return True
    except Exception as e:
        print(f" [ERROR] Database operation failed: {e}")
        conn.close()
        return False

if __name__ == "__main__":
    check_supabase()

