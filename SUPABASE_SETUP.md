# Supabase Database Configuration & Setup Guide

This project is fully configured to use **Supabase PostgreSQL** as its primary production database, adhering to all [Supabase Postgres Best Practices](.agents/skills/supabase-postgres-best-practices/SKILL.md) (Foreign Key indexing, Row-Level Security, connection pooling, and automated schema migration).

---

## 1. Quick Setup (3 Steps)

### Step 1: Get your Supabase Connection String
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Select your project (or click **New Project** to create one).
3. Navigate to **Project Settings** (gear icon) &rarr; **Database**.
4. Scroll to **Connection string** and select **URI**.
   - **Recommended (Connection Pooler, Port 6543)**:
     ```
     postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=require
     ```
   - **Direct connection (Port 5432)**:
     ```
     postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres?sslmode=require
     ```
   *(Note: Remember to replace `[YOUR-PASSWORD]` with your actual database password. If your password contains special characters like `@`, URL-encode it, e.g., `%40`)*.

---

### Step 2: Add to `.env`
Open `.env` in the project root and uncomment/set `DATABASE_URL`:
```env
DATABASE_URL=postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=require
```

---

### Step 3: Initialize Database & Verify
You have two easy ways to set up the tables and initial seed data:

#### Method A: Run the Automated Diagnostic & Migration Tool (Recommended)
Run:
```bash
python backend/test_supabase_connection.py
```
This script will:
1. Connect to Supabase with SSL.
2. Verify the PostgreSQL engine.
3. Automatically apply migrations to create all 19 relational tables with foreign keys and performance indexes.
4. Seed default departments, approved skills, and the convener account.

#### Method B: Paste SQL into the Supabase Dashboard
If you prefer running SQL directly in Supabase:
1. Open the Supabase Dashboard &rarr; **SQL Editor**.
2. Click **New query**.
3. Copy the contents of [`supabase_schema.sql`](supabase_schema.sql) and paste it into the editor.
4. Click **Run**.

---

## 2. Supabase Postgres Best Practices Implemented

| Category | Implementation in this project |
| :--- | :--- |
| **Row Level Security (RLS)** | Enabled across all 19 public tables with policies for `service_role`, `authenticated`, and `anon`. |
| **Foreign Key Indexes** | Every foreign key reference (e.g. `user_id`, `event_id`, `volunteer_id`, etc.) has an explicit index for 10-100x faster JOINs and cascade operations. |
| **Connection Pooling** | Full support for Supabase Supavisor Transaction Pooler (`port 6543`) with `pg8000` pure-Python driver and SSL. |
| **Dynamic URL Support** | Seamless switching between local development (SQLite) and Cloud Supabase (PostgreSQL) via `DATABASE_URL`. |

---

## 3. Starting the Application

Once your Supabase `DATABASE_URL` is configured in `.env`:
```bash
# Run backend
python backend/run.py

# Run frontend (in a separate terminal)
cd frontend
npm run dev
```

