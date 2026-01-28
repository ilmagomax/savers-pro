-- ============================================
-- SAVERS PRO - SCHEMA DATABASE BASE
-- Esegui PRIMA di new-features.sql
-- Supabase Dashboard > SQL Editor > New Query
-- ============================================

-- ============================================
-- ESTENSIONI
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ORGANIZZAZIONI (Multi-tenant)
-- ============================================
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Info base
    name TEXT NOT NULL,
    slug TEXT UNIQUE,
    logo_url TEXT,

    -- Owner
    owner_id UUID,

    -- Piano e Billing
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'business', 'enterprise')),
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'trialing', 'past_due', 'canceled', 'suspended')),

    -- Trial
    trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),

    -- Limiti
    max_members INTEGER DEFAULT 1,
    max_projects INTEGER DEFAULT 3,
    max_storage_mb INTEGER DEFAULT 100,

    -- Features
    features_enabled JSONB DEFAULT '{"crm": false, "api": false, "whitelabel": false}',

    -- Settings
    settings JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. PROFILI UTENTE
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,

    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    phone TEXT,

    org_role TEXT DEFAULT 'member' CHECK (org_role IN ('owner', 'admin', 'member', 'viewer')),
    is_super_admin BOOLEAN DEFAULT FALSE,

    -- Google Calendar
    google_access_token TEXT,
    google_refresh_token TEXT,
    google_token_expires_at TIMESTAMPTZ,
    google_calendar_id TEXT,

    -- Gamification
    total_xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,

    -- Preferenze
    theme TEXT DEFAULT 'light',
    language TEXT DEFAULT 'it',
    notification_email BOOLEAN DEFAULT TRUE,
    notification_push BOOLEAN DEFAULT TRUE,
    notification_sound BOOLEAN DEFAULT TRUE,

    -- Stato
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    banned_reason TEXT,
    onboarding_completed BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ
);

-- Foreign key per owner
ALTER TABLE organizations
ADD CONSTRAINT fk_org_owner
FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================
-- 3. SKILL CATEGORIES & SKILLS
-- ============================================
CREATE TABLE skill_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id),

    name TEXT NOT NULL,
    icon TEXT,
    color TEXT,
    description TEXT,
    position INTEGER DEFAULT 0
);

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES skill_categories(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    max_level INTEGER DEFAULT 10
);

CREATE TABLE user_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,

    xp INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, skill_id)
);

-- ============================================
-- 4. HABITS
-- ============================================
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT '✅',
    color TEXT DEFAULT '#6366f1',

    frequency TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekdays', 'weekends', 'weekly', 'custom')),
    target_days INTEGER[],
    reminder_time TIME,

    department TEXT DEFAULT 'personal' CHECK (department IN ('work', 'personal')),

    current_streak INTEGER DEFAULT 0,
    best_streak INTEGER DEFAULT 0,
    total_completions INTEGER DEFAULT 0,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    completed_at DATE NOT NULL,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(habit_id, completed_at)
);

-- ============================================
-- 5. TASKS
-- ============================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    project_id UUID,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    description TEXT,

    status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'review', 'done', 'blocked')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    quadrant INTEGER DEFAULT 2 CHECK (quadrant BETWEEN 1 AND 4),

    due_date DATE,
    due_time TIME,
    start_date DATE,
    completed_at TIMESTAMPTZ,

    estimated_minutes INTEGER,
    actual_minutes INTEGER DEFAULT 0,

    category TEXT,
    labels TEXT[],
    department TEXT DEFAULT 'work' CHECK (department IN ('work', 'personal')),

    position INTEGER DEFAULT 0,

    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,

    google_event_id TEXT,

    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. TRANSACTIONS (Finance)
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',

    description TEXT,
    category TEXT NOT NULL,

    date DATE NOT NULL,
    department TEXT DEFAULT 'personal' CHECK (department IN ('work', 'personal')),

    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,

    receipt_url TEXT,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'completed' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. BOOKS
-- ============================================
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    title TEXT NOT NULL,
    author TEXT,
    cover_url TEXT,
    isbn TEXT,

    status TEXT DEFAULT 'to_read' CHECK (status IN ('to_read', 'reading', 'completed', 'abandoned')),

    pages_total INTEGER,
    pages_read INTEGER DEFAULT 0,

    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    notes TEXT,

    started_at DATE,
    finished_at DATE,

    recommended_by UUID REFERENCES profiles(id),
    is_recommended BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. GOALS
-- ============================================
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    title TEXT NOT NULL,
    description TEXT,

    type TEXT DEFAULT 'personal' CHECK (type IN ('personal', 'team', 'org')),
    timeframe TEXT DEFAULT 'monthly' CHECK (timeframe IN ('weekly', 'monthly', 'quarterly', 'yearly')),

    target_value DECIMAL(12,2),
    current_value DECIMAL(12,2) DEFAULT 0,
    unit TEXT,

    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),

    due_date DATE,
    completed_at TIMESTAMPTZ,

    department TEXT DEFAULT 'personal' CHECK (department IN ('work', 'personal')),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. SAVERS LOGS
-- ============================================
CREATE TABLE savers_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    date DATE NOT NULL,

    silence_completed BOOLEAN DEFAULT FALSE,
    silence_minutes INTEGER,

    affirmations_completed BOOLEAN DEFAULT FALSE,
    affirmations_text TEXT,

    visualization_completed BOOLEAN DEFAULT FALSE,
    visualization_notes TEXT,

    exercise_completed BOOLEAN DEFAULT FALSE,
    exercise_minutes INTEGER,
    exercise_type TEXT,

    reading_completed BOOLEAN DEFAULT FALSE,
    reading_minutes INTEGER,
    reading_pages INTEGER,

    scribing_completed BOOLEAN DEFAULT FALSE,
    scribing_notes TEXT,

    mood INTEGER CHECK (mood >= 1 AND mood <= 5),
    mood_notes TEXT,

    sleep_hours DECIMAL(3,1),
    sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 5),

    water_glasses INTEGER DEFAULT 0,
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, date)
);

-- ============================================
-- 10. NOTES
-- ============================================
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    title TEXT,
    content TEXT NOT NULL,

    color TEXT DEFAULT '#ffffff',
    is_pinned BOOLEAN DEFAULT FALSE,

    tags TEXT[],

    project_id UUID,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. NOTIFICATIONS
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),

    type TEXT NOT NULL CHECK (type IN ('mention', 'assignment', 'deadline', 'comment', 'team_invite', 'system', 'achievement', 'crm_reminder')),
    title TEXT NOT NULL,
    body TEXT,

    entity_type TEXT,
    entity_id UUID,
    link TEXT,

    actor_id UUID REFERENCES profiles(id),

    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,

    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 12. POMODORO SESSIONS
-- ============================================
CREATE TABLE pomodoro_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,

    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,

    duration_minutes INTEGER DEFAULT 25,
    type TEXT DEFAULT 'work' CHECK (type IN ('work', 'short_break', 'long_break')),

    completed BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- ============================================
-- 13. ACHIEVEMENTS
-- ============================================
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,

    requirement_type TEXT NOT NULL,
    requirement_value INTEGER NOT NULL,

    xp_reward INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,

    unlocked_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, achievement_id)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_profiles_org ON profiles(organization_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_habits_user ON habits(user_id);
CREATE INDEX idx_habit_logs_habit ON habit_logs(habit_id);
CREATE INDEX idx_tasks_org ON tasks(organization_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE read = FALSE;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE savers_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE pomodoro_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
CREATE OR REPLACE FUNCTION get_user_org_id()
RETURNS UUID AS $$
    SELECT organization_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT is_super_admin FROM profiles WHERE id = auth.uid()),
        FALSE
    );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_org_admin()
RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT org_role IN ('owner', 'admin') FROM profiles WHERE id = auth.uid()),
        FALSE
    );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ============================================
-- RLS POLICIES
-- ============================================

-- ORGANIZATIONS
CREATE POLICY "Users can view own org" ON organizations
    FOR SELECT USING (id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Owners can update own org" ON organizations
    FOR UPDATE USING (owner_id = auth.uid() OR is_super_admin());

CREATE POLICY "Anyone can create org" ON organizations
    FOR INSERT WITH CHECK (true);

-- PROFILES
CREATE POLICY "Users can view profiles in same org" ON profiles
    FOR SELECT USING (organization_id = get_user_org_id() OR id = auth.uid() OR is_super_admin());

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- HABITS
CREATE POLICY "Users manage own habits" ON habits
    FOR ALL USING (user_id = auth.uid());

-- HABIT LOGS
CREATE POLICY "Users manage own habit logs" ON habit_logs
    FOR ALL USING (user_id = auth.uid());

-- TASKS
CREATE POLICY "Users can view tasks" ON tasks
    FOR SELECT USING (organization_id = get_user_org_id() OR created_by = auth.uid() OR is_super_admin());

CREATE POLICY "Users can create tasks" ON tasks
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update own tasks" ON tasks
    FOR UPDATE USING (created_by = auth.uid() OR is_org_admin());

CREATE POLICY "Users can delete own tasks" ON tasks
    FOR DELETE USING (created_by = auth.uid() OR is_org_admin());

-- TRANSACTIONS
CREATE POLICY "Users manage own transactions" ON transactions
    FOR ALL USING (user_id = auth.uid() OR is_super_admin());

-- BOOKS
CREATE POLICY "Users manage own books" ON books
    FOR ALL USING (user_id = auth.uid());

-- GOALS
CREATE POLICY "Users manage own goals" ON goals
    FOR ALL USING (user_id = auth.uid());

-- SAVERS LOGS
CREATE POLICY "Users manage own savers logs" ON savers_logs
    FOR ALL USING (user_id = auth.uid());

-- NOTES
CREATE POLICY "Users manage own notes" ON notes
    FOR ALL USING (user_id = auth.uid());

-- NOTIFICATIONS
CREATE POLICY "Users see own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- POMODORO
CREATE POLICY "Users manage own pomodoro" ON pomodoro_sessions
    FOR ALL USING (user_id = auth.uid());

-- USER ACHIEVEMENTS
CREATE POLICY "Users see own achievements" ON user_achievements
    FOR SELECT USING (user_id = auth.uid());

-- SKILL CATEGORIES (public read)
CREATE POLICY "Anyone can view skill categories" ON skill_categories
    FOR SELECT USING (true);

-- SKILLS (public read)
CREATE POLICY "Anyone can view skills" ON skills
    FOR SELECT USING (true);

-- USER SKILLS
CREATE POLICY "Users manage own skills" ON user_skills
    FOR ALL USING (user_id = auth.uid());

-- ============================================
-- TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_habits_updated_at
    BEFORE UPDATE ON habits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- SEED DATA
-- ============================================

-- Default skill categories
INSERT INTO skill_categories (name, icon, color, description, position) VALUES
    ('Performance', '🎭', '#EF4444', 'Competenze di performance e spettacolo', 1),
    ('Tecnica', '✨', '#8B5CF6', 'Abilità tecniche specifiche', 2),
    ('Business', '💼', '#3B82F6', 'Competenze commerciali e gestionali', 3),
    ('Relazioni', '🤝', '#10B981', 'Comunicazione e soft skills', 4),
    ('Crescita', '📚', '#F59E0B', 'Sviluppo personale e apprendimento', 5);

-- Default skills
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Baby Dance', 'Condurre balli di gruppo per bambini', '💃' FROM skill_categories WHERE name = 'Performance';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Giochi di Gruppo', 'Organizzare e gestire giochi', '🎮' FROM skill_categories WHERE name = 'Performance';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Animazione Feste', 'Intrattenimento completo per feste', '🎉' FROM skill_categories WHERE name = 'Performance';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Face Painting', 'Trucco artistico per bambini', '🎨' FROM skill_categories WHERE name = 'Tecnica';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Balloon Art', 'Sculture con palloncini', '🎈' FROM skill_categories WHERE name = 'Tecnica';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Magia Base', 'Trucchi di magia semplici', '🎩' FROM skill_categories WHERE name = 'Tecnica';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Vendita', 'Proporre e chiudere contratti', '💰' FROM skill_categories WHERE name = 'Business';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Preventivi', 'Creare preventivi efficaci', '📝' FROM skill_categories WHERE name = 'Business';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Gestione Genitori', 'Comunicazione con i genitori', '👨‍👩‍👧' FROM skill_categories WHERE name = 'Relazioni';
INSERT INTO skills (category_id, name, description, icon)
SELECT id, 'Public Speaking', 'Parlare in pubblico', '🎤' FROM skill_categories WHERE name = 'Crescita';

-- Default achievements
INSERT INTO achievements (code, name, description, icon, requirement_type, requirement_value, xp_reward) VALUES
    ('first_habit', 'Prima Abitudine', 'Crea la tua prima abitudine', '🌱', 'habits_created', 1, 10),
    ('week_warrior', 'Guerriero della Settimana', 'Completa tutte le abitudini per 7 giorni', '🔥', 'habit_streak', 7, 50),
    ('task_starter', 'Primo Passo', 'Completa il tuo primo task', '✅', 'tasks_completed', 1, 10),
    ('bookworm', 'Topo di Biblioteca', 'Leggi 10 libri', '📚', 'books_completed', 10, 150),
    ('early_bird', 'Mattiniero', 'Completa la routine S.A.V.E.R.S. 7 giorni di fila', '🌅', 'savers_streak', 7, 75);

-- ============================================
-- DONE! Schema base completato.
-- Ora esegui: sql/new-features.sql
-- ============================================
