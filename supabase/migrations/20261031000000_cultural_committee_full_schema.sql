-- =====================================================================
-- SUPABASE POSTGRESQL SCHEMA FOR TAPMI CULTURAL COMMITTEE
-- Conforms to Supabase Postgres Best Practices:
--   - Lowercase identifiers
--   - Indexed Foreign Keys for fast JOINs and CASCADE operations
--   - Row Level Security (RLS) enabled on all tables
--   - Grants for service_role, authenticated, and anon roles
-- =====================================================================

-- 1. USERS & PROFILES
CREATE TABLE IF NOT EXISTS public.users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    role TEXT NOT NULL CHECK (role IN ('convener', 'co_convener', 'volunteer', 'core_committee')),
    status TEXT NOT NULL DEFAULT 'pending_activation' CHECK (status IN ('pending_activation', 'active', 'locked', 'inactive')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_login_at TEXT
);

CREATE TABLE IF NOT EXISTS public.volunteer_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES public.users(id) ON DELETE SET NULL,
    student_id TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    interviewed_by TEXT,
    email TEXT NOT NULL UNIQUE,
    active_status INTEGER NOT NULL DEFAULT 1,
    created_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.core_committee_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    created_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- 2. SKILLS & DEPARTMENTS
CREATE TABLE IF NOT EXISTS public.skills (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'retired')),
    created_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    approved_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    approved_at TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.volunteer_skills (
    volunteer_id BIGINT NOT NULL REFERENCES public.volunteer_profiles(id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    PRIMARY KEY (volunteer_id, skill_id)
);

CREATE TABLE IF NOT EXISTS public.departments (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS public.volunteer_preferences (
    id BIGSERIAL PRIMARY KEY,
    volunteer_id BIGINT NOT NULL REFERENCES public.volunteer_profiles(id) ON DELETE CASCADE,
    department_name TEXT NOT NULL,
    preference_rank INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    UNIQUE (volunteer_id, department_name)
);

-- 3. EVENTS & REQUIREMENTS
CREATE TABLE IF NOT EXISTS public.events (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    starts_at TEXT NOT NULL,
    ends_at TEXT NOT NULL,
    venue TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('draft', 'upcoming', 'ongoing', 'completed', 'cancelled', 'archived')),
    created_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    updated_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS public.department_heads (
    event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    department_id BIGINT NOT NULL REFERENCES public.departments(id),
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    assigned_at TEXT NOT NULL,
    PRIMARY KEY (event_id, department_id)
);

CREATE TABLE IF NOT EXISTS public.volunteer_availability (
    id BIGSERIAL PRIMARY KEY,
    volunteer_id BIGINT NOT NULL REFERENCES public.volunteer_profiles(id) ON DELETE CASCADE,
    event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    available INTEGER NOT NULL DEFAULT 1,
    availability_start TEXT,
    availability_end TEXT,
    max_hours NUMERIC NOT NULL DEFAULT 8.0,
    notes TEXT,
    UNIQUE (volunteer_id, event_id)
);

CREATE TABLE IF NOT EXISTS public.event_requirements (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    department_id BIGINT NOT NULL REFERENCES public.departments(id),
    role_name TEXT NOT NULL,
    headcount INTEGER NOT NULL CHECK (headcount >= 0),
    priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'normal')),
    duration_hours NUMERIC CHECK (duration_hours IS NULL OR duration_hours >= 0),
    workload_value NUMERIC CHECK (workload_value IS NULL OR workload_value >= 0),
    workload_unit TEXT,
    service_time_value NUMERIC,
    service_time_unit TEXT,
    peak_window_value NUMERIC,
    peak_window_unit TEXT,
    requirement_source TEXT NOT NULL CHECK (requirement_source IN ('fixed_headcount', 'workload_calculation')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.requirement_skills (
    requirement_id BIGINT NOT NULL REFERENCES public.event_requirements(id) ON DELETE CASCADE,
    skill_id BIGINT NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
    is_mandatory INTEGER NOT NULL DEFAULT 1,
    is_preferred INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (requirement_id, skill_id)
);

-- 4. ALLOCATIONS & ASSIGNMENTS
CREATE TABLE IF NOT EXISTS public.allocation_runs (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    algorithm TEXT NOT NULL,
    input_snapshot TEXT NOT NULL,
    input_fingerprint TEXT,
    solver_status TEXT,
    metrics TEXT,
    result_summary TEXT,
    run_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    is_simulation INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.allocation_versions (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    parent_version_id BIGINT REFERENCES public.allocation_versions(id) ON DELETE SET NULL,
    source_run_id BIGINT REFERENCES public.allocation_runs(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'published', 'superseded', 'rejected')),
    created_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    change_summary TEXT,
    row_version INTEGER NOT NULL DEFAULT 1,
    UNIQUE (event_id, version_number)
);

CREATE TABLE IF NOT EXISTS public.assignments (
    id BIGSERIAL PRIMARY KEY,
    allocation_version_id BIGINT NOT NULL REFERENCES public.allocation_versions(id) ON DELETE CASCADE,
    requirement_id BIGINT NOT NULL REFERENCES public.event_requirements(id),
    volunteer_id BIGINT NOT NULL REFERENCES public.volunteer_profiles(id),
    assigned_by BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    assignment_source TEXT NOT NULL CHECK (assignment_source IN ('greedy', 'ilp', 'manual', 'imported')),
    skill_override INTEGER NOT NULL DEFAULT 0,
    override_reason TEXT,
    created_at TEXT NOT NULL,
    UNIQUE (allocation_version_id, volunteer_id)
);

CREATE TABLE IF NOT EXISTS public.allocation_approvals (
    id BIGSERIAL PRIMARY KEY,
    allocation_version_id BIGINT NOT NULL REFERENCES public.allocation_versions(id) ON DELETE CASCADE,
    approved_by BIGINT NOT NULL REFERENCES public.users(id),
    decision TEXT NOT NULL CHECK (decision IN ('approved', 'rejected')),
    comment TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.published_allocations (
    event_id BIGINT PRIMARY KEY REFERENCES public.events(id) ON DELETE CASCADE,
    allocation_version_id BIGINT NOT NULL UNIQUE REFERENCES public.allocation_versions(id),
    published_by BIGINT NOT NULL REFERENCES public.users(id),
    published_at TEXT NOT NULL
);

-- 5. AUDIT & AUTHENTICATION
CREATE TABLE IF NOT EXISTS public.audit_log (
    id BIGSERIAL PRIMARY KEY,
    actor_user_id BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id BIGINT,
    before_data TEXT,
    after_data TEXT,
    reason TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.otp_challenges (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES public.users(id) ON DELETE CASCADE,
    volunteer_profile_id BIGINT REFERENCES public.volunteer_profiles(id) ON DELETE CASCADE,
    purpose TEXT NOT NULL CHECK (purpose IN ('activation', 'recovery')),
    otp_hash TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    consumed_at TEXT,
    created_at TEXT NOT NULL
);

-- =====================================================================
-- PERFORMANCE INDEXES (Foreign Keys & Common Lookups)
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_volunteers_user_id ON public.volunteer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_volunteers_student_id ON public.volunteer_profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_volunteers_email ON public.volunteer_profiles(email);
CREATE INDEX IF NOT EXISTS idx_volunteers_created_by ON public.volunteer_profiles(created_by);

CREATE INDEX IF NOT EXISTS idx_skills_created_by ON public.skills(created_by);
CREATE INDEX IF NOT EXISTS idx_skills_approved_by ON public.skills(approved_by);
CREATE INDEX IF NOT EXISTS idx_volunteer_skills_skill_id ON public.volunteer_skills(skill_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_preferences_vol_id ON public.volunteer_preferences(volunteer_id);

CREATE INDEX IF NOT EXISTS idx_events_status_starts ON public.events(status, starts_at);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON public.events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_updated_by ON public.events(updated_by);

CREATE INDEX IF NOT EXISTS idx_department_heads_user_event ON public.department_heads(user_id, event_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_department_heads_unique_member_per_event ON public.department_heads(event_id, user_id);
CREATE INDEX IF NOT EXISTS idx_department_heads_dept ON public.department_heads(department_id);

CREATE INDEX IF NOT EXISTS idx_volunteer_avail_event ON public.volunteer_availability(event_id);
CREATE INDEX IF NOT EXISTS idx_requirements_event ON public.event_requirements(event_id);
CREATE INDEX IF NOT EXISTS idx_requirements_dept ON public.event_requirements(department_id);
CREATE INDEX IF NOT EXISTS idx_requirement_skills_skill ON public.requirement_skills(skill_id);

CREATE INDEX IF NOT EXISTS idx_alloc_runs_event ON public.allocation_runs(event_id);
CREATE INDEX IF NOT EXISTS idx_alloc_runs_user ON public.allocation_runs(run_by);
CREATE INDEX IF NOT EXISTS idx_alloc_versions_event ON public.allocation_versions(event_id, version_number);
CREATE INDEX IF NOT EXISTS idx_alloc_versions_parent ON public.allocation_versions(parent_version_id);
CREATE INDEX IF NOT EXISTS idx_alloc_versions_source_run ON public.allocation_versions(source_run_id);
CREATE INDEX IF NOT EXISTS idx_alloc_versions_created_by ON public.allocation_versions(created_by);

CREATE INDEX IF NOT EXISTS idx_assignments_version_vol ON public.assignments(allocation_version_id, volunteer_id);
CREATE INDEX IF NOT EXISTS idx_assignments_requirement ON public.assignments(requirement_id);
CREATE INDEX IF NOT EXISTS idx_assignments_volunteer ON public.assignments(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_assignments_assigned_by ON public.assignments(assigned_by);

CREATE INDEX IF NOT EXISTS idx_alloc_approvals_version ON public.allocation_approvals(allocation_version_id);
CREATE INDEX IF NOT EXISTS idx_alloc_approvals_user ON public.allocation_approvals(approved_by);
CREATE INDEX IF NOT EXISTS idx_published_alloc_by ON public.published_allocations(published_by);

CREATE INDEX IF NOT EXISTS idx_audit_entity ON public.audit_log(entity_type, entity_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON public.audit_log(actor_user_id);

CREATE INDEX IF NOT EXISTS idx_otp_user ON public.otp_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_volunteer ON public.otp_challenges(volunteer_profile_id);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.core_committee_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.department_heads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requirement_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allocation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allocation_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allocation_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.published_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_challenges ENABLE ROW LEVEL SECURITY;

-- Allow full access to service_role (used by backend API connecting with service_role / db connection string)
DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "service_role_all" ON public.%I', tbl);
        EXECUTE format('CREATE POLICY "service_role_all" ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', tbl);

        EXECUTE format('DROP POLICY IF EXISTS "authenticated_all" ON public.%I', tbl);
        EXECUTE format('CREATE POLICY "authenticated_all" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', tbl);

        EXECUTE format('DROP POLICY IF EXISTS "anon_read" ON public.%I', tbl);
        EXECUTE format('CREATE POLICY "anon_read" ON public.%I FOR SELECT TO anon USING (true)', tbl);
    END LOOP;
END $$;

-- Table and Sequence Grants
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, authenticated, service_role;

-- =====================================================================
-- INITIAL ESSENTIAL SEED DATA
-- =====================================================================
INSERT INTO public.departments (name, description, active) VALUES
    ('Stage & Backstage Management', 'Stage logistics, greenroom, lighting, and audio management', 1),
    ('Sponsorship & Fundraising', 'Brand partnerships, corporate sponsorship, stall management', 1),
    ('IT & Technical Support', 'Audio-visual systems, networking, projection, live streams', 1),
    ('Logistics & Operations', 'Procurement, stage setup, vendor coordination, materials transport', 1),
    ('Marketing & Promotions', 'Social media, campus outreach, poster design, brand engagement', 1),
    ('Participant Coordination', 'Artist liaison, contestant registration, hospitality desks', 1),
    ('Hospitality & Guest Handling', 'VIP reception, travel, accommodation, campus guides', 1),
    ('Crowd Management & Security', 'Access control, queue management, safety guidelines', 1)
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.skills (name, description, status, created_at) VALUES
    ('Technical Support', 'Standard skill: Technical Support', 'approved', NOW()::text),
    ('Networking', 'Standard skill: Networking', 'approved', NOW()::text),
    ('Stage & Backstage Management', 'Standard skill: Stage & Backstage Management', 'approved', NOW()::text),
    ('Logistics', 'Standard skill: Logistics', 'approved', NOW()::text),
    ('Vendor Management', 'Standard skill: Vendor Management', 'approved', NOW()::text),
    ('Stall Management', 'Standard skill: Stall Management', 'approved', NOW()::text),
    ('Event Coordination', 'Standard skill: Event Coordination', 'approved', NOW()::text),
    ('Team Leadership', 'Standard skill: Team Leadership', 'approved', NOW()::text),
    ('Participant Coordination', 'Standard skill: Participant Coordination', 'approved', NOW()::text),
    ('Marketing & Promotions', 'Standard skill: Marketing & Promotions', 'approved', NOW()::text),
    ('Social Media & Content Creation', 'Standard skill: Social Media & Content Creation', 'approved', NOW()::text),
    ('Branding & Visual Design', 'Standard skill: Branding & Visual Design', 'approved', NOW()::text),
    ('Public Relations & Outreach', 'Standard skill: Public Relations & Outreach', 'approved', NOW()::text),
    ('Anchoring & Public Speaking', 'Standard skill: Anchoring & Public Speaking', 'approved', NOW()::text),
    ('Theatre & Acting', 'Standard skill: Theatre & Acting', 'approved', NOW()::text),
    ('Scriptwriting', 'Standard skill: Scriptwriting', 'approved', NOW()::text),
    ('Art, Props & Decoration', 'Standard skill: Art, Props & Decoration', 'approved', NOW()::text),
    ('Dance & Choreography', 'Standard skill: Dance & Choreography', 'approved', NOW()::text),
    ('Event Volunteering', 'Standard skill: Event Volunteering', 'approved', NOW()::text),
    ('Sponsorship & Fundraising', 'Standard skill: Sponsorship & Fundraising', 'approved', NOW()::text),
    ('Budgeting & Finance', 'Standard skill: Budgeting & Finance', 'approved', NOW()::text),
    ('Hospitality & Guest Handling', 'Standard skill: Hospitality & Guest Handling', 'approved', NOW()::text),
    ('Crowd Management & Security', 'Standard skill: Crowd Management & Security', 'approved', NOW()::text)
ON CONFLICT (name) DO NOTHING;

