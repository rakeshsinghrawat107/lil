---
title: TAPMI Cultural Committee Allocation System
emoji: 🎭
colorFrom: orange
colorTo: red
sdk: docker
app_port: 7860
pinned: false
---

# Cultural Committee Volunteer Management and Event Resource Allocation System
**Pilot Event:** Kala Fest  
**Institution:** T. A. Pai Management Institute (TAPMI), Manipal  
**Architecture:** Python + Flask + PuLP ILP Optimizer + Supabase PostgreSQL + React + Vite  
**Visual System:** Minimal White & Warm Orange (`#E8752E`)

---

## 1. System Overview

This web-based decision-support system manages cultural committee volunteers and allocates them to departments and roles for cultural events (piloted with Kala Fest).

### Key Capabilities
- **Volunteer Management:** Register volunteers with unique University Student IDs, track approved skills, manage availability and active status.
- **Volunteer Self-Service Portal:** View published event assignments, manage approved skills catalog selections, and view assignment history.
- **Department Requirements & Staffing Capacity:** Define staffing requirements using either fixed headcount or the workload-based capacity formula:
  $$\text{Required Staff} = \left\lceil \frac{\text{Workload} \times \text{Service Time}}{\text{Peak Window}} \right\rceil$$
- **Real Python Allocation Engine:**
  - **Greedy Baseline:** Deterministic priority-first matching (Critical $\rightarrow$ High $\rightarrow$ Normal) with skill fit and preference scoring.
  - **PuLP ILP Optimizer:** Integer Linear Programming with binary decision variables $x_{v,p}$, respecting mandatory skills, volunteer uniqueness, and a balanced multi-criteria objective.
  - **Side-by-Side Algorithm Comparison:** Evaluates both algorithms on the exact same input snapshot and reports filled positions, vacancies, coverage, preference satisfaction, and runtimes.
- **Shortage Diagnostics & Evidence-Based Recommendations:** Identifies available unassigned volunteers as reallocation candidates and pinpoints genuine skill gaps.
- **Allocation Lifecycle & Versioning:** Enforces Draft $\rightarrow$ Review $\rightarrow$ Approval $\rightarrow$ Atomic Publication. Volunteers never see draft allocations.
- **What-If Scenario Simulator:** Tests surge demand, volunteer dropouts, and simulated cohorts on isolated deep copies without mutating live records (`Simulation · Not published`).
- **Campus Login Interface:** Fully opaque login panel rendered over the softened TAPMI campus background image (`Icon.jpg`).

---

## 2. Technology Stack

- **Backend:** Python 3.10+ / 3.12, Flask 3.1+, Flask-CORS, Werkzeug, Gunicorn
- **Optimization:** PuLP 2.9.0 (CBC solver for binary integer programming)
- **Data & Numerical Processing:** NumPy, python-dateutil
- **Database:** Supabase PostgreSQL 17 (via pure-Python `pg8000` driver with SSL) and local standalone SQLite fallback
- **Roster exports:** CSV and multi-sheet Excel files for published allocations
- **Frontend:** React 18, Vite 5, Lucide Line Icons, Custom White & Warm Orange Design System

---

## 3. Local Setup Instructions

### Prerequisites
- Python 3.10 or higher
- Node.js 18+ and npm
- Supabase PostgreSQL (or local SQLite)

### Step 1: Configure Environment Variables
Copy `.env.example` to `.env` and fill in your Supabase connection URL:
```ini
DATABASE_URL=postgresql://postgres.ssmzoukesrdsgdvglhyx:Kingpin0707seryvhabw@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require
SECRET_KEY=96fe1f4dfbbf15dcf02fede4cd3c361004c0f05a09c2486d
PORT=5000
```

---

### Step 2: Install Backend Dependencies
```bash
pip install -r backend/requirements.txt
```

---

### Step 3: Run Database Migrations & Seed Pilot Data
Verify Supabase and automatically apply migrations:
```bash
python backend/test_supabase_connection.py
```

---

### Step 4: Install Frontend Dependencies & Build
```bash
cd frontend
npm.cmd install
npm.cmd run build
cd ..
```

---

### Step 5: Start the Full-Stack Application
```bash
python backend/run.py
```
Open **[http://localhost:5000](http://localhost:5000)** in your browser.

---

## 4. Running Automated Tests

Run the complete test suite with pytest:
```bash
python -m pytest backend/tests
```
All 17 tests verify capacity calculation, eligibility hard rules, algorithm comparisons, authentication, lifecycle workflows, and simulation deep-copy isolation.

---

## 5. Demo Credentials

The database comes pre-seeded with test accounts:

| Role | Email | Password | Access Level |
|---|---|---|---|
| **Convener** | `convener@tapmi.edu.in` | `convener123` | Full organizer authority |
| **Co-convener** | `coconvener@tapmi.edu.in` | `coconvener123` | Full organizer authority (equal permissions) |
| **Volunteer (Aarohi Anchal)** | `aarohi.anchal@tapmi.edu.in` | `volunteer123` | Published assignments, skills catalog |

*(Quick prefill buttons are provided on the login page for instantaneous demo access)*
