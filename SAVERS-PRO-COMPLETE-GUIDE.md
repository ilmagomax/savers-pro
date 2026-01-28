# 🚀 SAVERS PRO SaaS - Guida Completa

## Documento Master per Sviluppo e Commercializzazione

---

# PARTE 1: SETUP SUPABASE

## 1.1 Creazione Progetto

```
1. Vai su https://supabase.com
2. Crea account (usa Google per velocità)
3. Click "New Project"
4. Compila:
   - Name: savers-pro
   - Database Password: [GENERA UNA SICURA E SALVALA!]
   - Region: Frankfurt (eu-central-1) ← Più vicino all'Italia
5. Click "Create new project"
6. Attendi 2-3 minuti per il setup
```

## 1.2 Credenziali da Salvare

Dopo la creazione, vai su **Settings > API** e copia:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx (SEGRETA!)
```

**⚠️ IMPORTANTE:** 
- `ANON_KEY` = pubblica, va nel frontend
- `SERVICE_KEY` = SEGRETA, solo backend/edge functions

## 1.3 Configurare Google OAuth

```
1. Vai su Supabase Dashboard > Authentication > Providers
2. Trova "Google" e abilita
3. Ti servono Client ID e Secret da Google Cloud Console

In Google Cloud Console (console.cloud.google.com):
1. Crea progetto o usa esistente
2. APIs & Services > Credentials
3. Create Credentials > OAuth 2.0 Client IDs
4. Application type: Web application
5. Authorized redirect URIs: 
   https://xxxxx.supabase.co/auth/v1/callback
6. Copia Client ID e Client Secret in Supabase
```

---

# PARTE 2: SCHEMA DATABASE COMPLETO

## 2.1 Esecuzione Schema

Vai su **Supabase Dashboard > SQL Editor > New Query** e esegui questo schema completo:

```sql
-- ============================================
-- SAVERS PRO - SCHEMA DATABASE COMPLETO
-- Versione: 1.0
-- Include: Multi-tenant, Team, Progetti, CRM
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
    owner_id UUID, -- Riferimento a profiles (aggiunto dopo)
    
    -- Piano e Billing
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'business', 'enterprise')),
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'trialing', 'past_due', 'canceled', 'suspended')),
    
    -- Trial
    trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
    
    -- Limiti (basati sul piano)
    max_members INTEGER DEFAULT 1,
    max_projects INTEGER DEFAULT 3,
    max_storage_mb INTEGER DEFAULT 100,
    
    -- Features abilitate
    features_enabled JSONB DEFAULT '{"crm": false, "api": false, "whitelabel": false}',
    
    -- Settings
    settings JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. PROFILI UTENTE
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    
    -- Info base
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    phone TEXT,
    
    -- Ruolo nell'organizzazione
    org_role TEXT DEFAULT 'member' CHECK (org_role IN ('owner', 'admin', 'member', 'viewer')),
    
    -- Super Admin (per te)
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
    
    -- Onboarding
    onboarding_completed BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ
);

-- Aggiungi foreign key per owner
ALTER TABLE organizations 
ADD CONSTRAINT fk_org_owner 
FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- ============================================
-- 3. TEAM
-- ============================================
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#6366f1',
    icon TEXT DEFAULT '👥',
    
    is_default BOOLEAN DEFAULT FALSE,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    role TEXT DEFAULT 'member' CHECK (role IN ('leader', 'member')),
    
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(team_id, user_id)
);

-- ============================================
-- 4. PROGETTI
-- ============================================
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    
    -- Info
    name TEXT NOT NULL,
    description TEXT,
    objective TEXT,
    color TEXT DEFAULT '#10b981',
    cover_image_url TEXT,
    
    -- Status
    status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'active', 'on_hold', 'completed', 'archived')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Date
    start_date DATE,
    due_date DATE,
    completed_at TIMESTAMPTZ,
    
    -- Budget
    budget_estimated DECIMAL(12,2) DEFAULT 0,
    budget_spent DECIMAL(12,2) DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    
    -- Template
    is_template BOOLEAN DEFAULT FALSE,
    template_name TEXT,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    permission TEXT DEFAULT 'viewer' CHECK (permission IN ('owner', 'editor', 'viewer')),
    
    added_by UUID REFERENCES profiles(id),
    added_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(project_id, user_id)
);

-- ============================================
-- 5. TASKS
-- ============================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE, -- Subtask
    
    -- Info
    title TEXT NOT NULL,
    description TEXT,
    
    -- Status
    status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'doing', 'review', 'done', 'blocked')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    quadrant INTEGER DEFAULT 2 CHECK (quadrant BETWEEN 1 AND 4), -- Eisenhower
    
    -- Date
    due_date DATE,
    due_time TIME,
    start_date DATE,
    completed_at TIMESTAMPTZ,
    
    -- Time tracking
    estimated_minutes INTEGER,
    actual_minutes INTEGER DEFAULT 0,
    
    -- Categorizzazione
    category TEXT,
    labels TEXT[],
    department TEXT DEFAULT 'work' CHECK (department IN ('work', 'personal')),
    
    -- Ordinamento Kanban
    position INTEGER DEFAULT 0,
    
    -- Ricorrenza
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,
    
    -- Google Calendar
    google_event_id TEXT,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE task_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    assigned_by UUID REFERENCES profiles(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(task_id, user_id)
);

CREATE TABLE task_checklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    
    title TEXT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    position INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. COMMENTI
-- ============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Target (uno dei due)
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    
    -- Content
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    
    -- Menzioni
    mentions UUID[],
    
    -- Edit
    edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT comment_has_target CHECK (task_id IS NOT NULL OR project_id IS NOT NULL)
);

-- ============================================
-- 7. NOTIFICHE
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),
    
    -- Tipo e contenuto
    type TEXT NOT NULL CHECK (type IN ('mention', 'assignment', 'deadline', 'comment', 'team_invite', 'system', 'achievement', 'crm_reminder')),
    title TEXT NOT NULL,
    body TEXT,
    
    -- Link
    entity_type TEXT,
    entity_id UUID,
    link TEXT,
    
    -- Chi ha generato
    actor_id UUID REFERENCES profiles(id),
    
    -- Stato
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- Email
    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. ACTIVITY LOG
-- ============================================
CREATE TABLE activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Contesto
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    
    -- Chi e cosa
    user_id UUID REFERENCES profiles(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    
    -- Dettagli
    details JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. RISORSE PROGETTO
-- ============================================
CREATE TABLE project_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,
    type TEXT DEFAULT 'material' CHECK (type IN ('material', 'tool', 'service', 'venue', 'person')),
    description TEXT,
    
    quantity INTEGER DEFAULT 1,
    cost_per_unit DECIMAL(10,2) DEFAULT 0,
    
    status TEXT DEFAULT 'needed' CHECK (status IN ('needed', 'ordered', 'available', 'used')),
    
    assigned_to UUID REFERENCES profiles(id),
    supplier TEXT,
    notes TEXT,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. PROBLEMI PROGETTO
-- ============================================
CREATE TABLE project_issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    title TEXT NOT NULL,
    description TEXT,
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
    
    reported_by UUID REFERENCES profiles(id),
    assigned_to UUID REFERENCES profiles(id),
    
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. HABITS
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
    target_days INTEGER[], -- Per custom: [1,2,3,4,5] = Lun-Ven
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
-- 12. TRANSACTIONS (Finance)
-- ============================================
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),
    
    -- Collegamento opzionale
    event_id UUID, -- Riferimento a eventi
    crm_contact_id UUID, -- Riferimento a CRM
    
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    
    description TEXT,
    category TEXT NOT NULL,
    
    date DATE NOT NULL,
    department TEXT DEFAULT 'personal' CHECK (department IN ('work', 'personal')),
    
    -- Ricorrenza
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_rule TEXT,
    
    -- Receipt
    receipt_url TEXT,
    
    -- Payment
    payment_method TEXT,
    payment_status TEXT DEFAULT 'completed' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. SKILLS
-- ============================================
CREATE TABLE skill_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id), -- NULL = globali
    
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
-- 14. BOOKS
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
    
    -- Consigliato da admin
    recommended_by UUID REFERENCES profiles(id),
    is_recommended BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 15. GOALS
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
-- 16. SAVERS ROUTINE
-- ============================================
CREATE TABLE savers_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    date DATE NOT NULL,
    
    -- S.A.V.E.R.S.
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
    
    -- Wellness
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
-- 17. EVENTS (Calendario/Lavori)
-- ============================================
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id),
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    
    -- CRM link
    crm_contact_id UUID, -- Riferimento a contacts CRM
    
    title TEXT NOT NULL,
    description TEXT,
    
    event_type TEXT CHECK (event_type IN ('show', 'rehearsal', 'meeting', 'personal', 'birthday', 'corporate', 'other')),
    
    location TEXT,
    location_url TEXT,
    
    -- Date
    date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    all_day BOOLEAN DEFAULT FALSE,
    
    -- Finanze
    earnings DECIMAL(12,2) DEFAULT 0,
    expenses DECIMAL(12,2) DEFAULT 0,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'partial', 'paid', 'canceled')),
    
    -- Department
    department TEXT DEFAULT 'work' CHECK (department IN ('work', 'personal')),
    
    -- Google Calendar
    google_event_id TEXT,
    google_calendar_id TEXT,
    
    -- Status
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('tentative', 'confirmed', 'canceled')),
    
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 18. CRM - CONTACTS
-- ============================================
CREATE TABLE crm_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Info base
    first_name TEXT NOT NULL,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    phone_secondary TEXT,
    
    -- Tipo
    type TEXT DEFAULT 'private' CHECK (type IN ('private', 'company', 'agency', 'school', 'other')),
    company_name TEXT,
    job_title TEXT,
    
    -- Indirizzo
    address TEXT,
    city TEXT,
    province TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Italia',
    
    -- Fonte acquisizione
    source TEXT CHECK (source IN ('referral', 'google', 'instagram', 'facebook', 'website', 'event', 'cold_call', 'other')),
    source_detail TEXT, -- Es: "Segnalato da Mario Rossi"
    
    -- Preferenze
    preferred_contact_method TEXT DEFAULT 'whatsapp' CHECK (preferred_contact_method IN ('phone', 'whatsapp', 'email', 'sms')),
    best_time_to_contact TEXT,
    
    -- Tags e note
    tags TEXT[],
    notes TEXT,
    
    -- Rating interno
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    
    -- Date importanti
    birthday DATE,
    anniversary DATE,
    
    -- Figli (per feste bambini)
    children JSONB, -- [{"name": "Marco", "birthday": "2020-05-15", "notes": "ama Spiderman"}]
    
    -- Statistiche
    total_events INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0,
    last_event_date DATE,
    
    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    
    -- Assegnazione
    assigned_to UUID REFERENCES profiles(id),
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 19. CRM - PIPELINE (Trattative)
-- ============================================
CREATE TABLE crm_deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES crm_contacts(id) ON DELETE CASCADE,
    
    -- Info
    title TEXT NOT NULL, -- Es: "Festa compleanno Marco - 15 Marzo"
    description TEXT,
    
    -- Pipeline stage
    stage TEXT DEFAULT 'new' CHECK (stage IN ('new', 'contacted', 'quote_sent', 'negotiation', 'won', 'lost')),
    
    -- Valore
    value DECIMAL(12,2) DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    probability INTEGER DEFAULT 50 CHECK (probability >= 0 AND probability <= 100),
    
    -- Date
    event_date DATE, -- Data dell'evento
    expected_close_date DATE,
    closed_at TIMESTAMPTZ,
    
    -- Motivo perso
    lost_reason TEXT CHECK (lost_reason IN ('price', 'competitor', 'timing', 'no_response', 'changed_mind', 'other')),
    lost_reason_detail TEXT,
    
    -- Tipo evento
    event_type TEXT,
    
    -- Assegnazione
    assigned_to UUID REFERENCES profiles(id),
    
    -- Preventivo collegato
    quote_id UUID, -- Riferimento a crm_quotes
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 20. CRM - PREVENTIVI
-- ============================================
CREATE TABLE crm_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    deal_id UUID REFERENCES crm_deals(id) ON DELETE SET NULL,
    contact_id UUID NOT NULL REFERENCES crm_contacts(id) ON DELETE CASCADE,
    
    -- Info
    quote_number TEXT NOT NULL, -- Es: "PRV-2026-001"
    title TEXT NOT NULL,
    
    -- Date
    issue_date DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    event_date DATE,
    
    -- Contenuto
    items JSONB NOT NULL, -- [{"description": "Animazione 3 ore", "quantity": 1, "unit_price": 200}]
    
    -- Totali
    subtotal DECIMAL(12,2) DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    tax_percent DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) DEFAULT 0,
    
    -- Termini
    terms TEXT,
    notes TEXT,
    
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'accepted', 'rejected', 'expired')),
    
    -- Tracking
    sent_at TIMESTAMPTZ,
    viewed_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    
    -- PDF
    pdf_url TEXT,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 21. CRM - FOLLOW-UP / TASKS
-- ============================================
CREATE TABLE crm_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES crm_contacts(id) ON DELETE CASCADE,
    deal_id UUID REFERENCES crm_deals(id) ON DELETE CASCADE,
    
    -- Info
    title TEXT NOT NULL,
    description TEXT,
    
    type TEXT DEFAULT 'call' CHECK (type IN ('call', 'email', 'whatsapp', 'meeting', 'follow_up', 'other')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Scadenza
    due_date DATE,
    due_time TIME,
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'canceled')),
    completed_at TIMESTAMPTZ,
    
    -- Reminder
    reminder_at TIMESTAMPTZ,
    reminder_sent BOOLEAN DEFAULT FALSE,
    
    -- Assegnazione
    assigned_to UUID REFERENCES profiles(id),
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 22. CRM - COMUNICAZIONI LOG
-- ============================================
CREATE TABLE crm_communications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES crm_contacts(id) ON DELETE CASCADE,
    deal_id UUID REFERENCES crm_deals(id) ON DELETE SET NULL,
    
    -- Tipo
    type TEXT NOT NULL CHECK (type IN ('call_in', 'call_out', 'email_in', 'email_out', 'whatsapp_in', 'whatsapp_out', 'meeting', 'note')),
    
    -- Contenuto
    subject TEXT,
    content TEXT,
    
    -- Durata (per chiamate)
    duration_minutes INTEGER,
    
    -- Outcome
    outcome TEXT, -- Es: "Interessato, richiamare lunedì"
    
    -- Allegati
    attachments JSONB, -- [{"name": "preventivo.pdf", "url": "..."}]
    
    -- Chi
    user_id UUID REFERENCES profiles(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 23. CRM - TEMPLATES
-- ============================================
CREATE TABLE crm_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    type TEXT NOT NULL CHECK (type IN ('email', 'whatsapp', 'sms', 'quote')),
    name TEXT NOT NULL,
    subject TEXT, -- Per email
    content TEXT NOT NULL,
    
    -- Variabili disponibili: {{contact_name}}, {{event_date}}, {{quote_total}}, etc.
    variables TEXT[],
    
    is_default BOOLEAN DEFAULT FALSE,
    
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 24. NOTES
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
    
    -- Collegamento opzionale
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 25. POMODORO SESSIONS
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
-- 26. ACHIEVEMENTS / BADGES
-- ============================================
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    
    -- Requisiti
    requirement_type TEXT NOT NULL, -- 'habit_streak', 'tasks_completed', 'books_read', etc.
    requirement_value INTEGER NOT NULL,
    
    -- Reward
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
-- 27. AUDIT LOG (per Super Admin)
-- ============================================
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES profiles(id),
    organization_id UUID REFERENCES organizations(id),
    
    action TEXT NOT NULL, -- 'login', 'logout', 'create', 'update', 'delete', 'export', etc.
    entity_type TEXT,
    entity_id UUID,
    
    details JSONB,
    
    ip_address TEXT,
    user_agent TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES PER PERFORMANCE
-- ============================================

-- Organizations
CREATE INDEX idx_org_slug ON organizations(slug);
CREATE INDEX idx_org_plan ON organizations(plan);

-- Profiles
CREATE INDEX idx_profiles_org ON profiles(organization_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_super_admin ON profiles(is_super_admin) WHERE is_super_admin = TRUE;

-- Teams
CREATE INDEX idx_teams_org ON teams(organization_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);

-- Projects
CREATE INDEX idx_projects_org ON projects(organization_id);
CREATE INDEX idx_projects_team ON projects(team_id);
CREATE INDEX idx_projects_status ON projects(status);

-- Tasks
CREATE INDEX idx_tasks_org ON tasks(organization_id);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due ON tasks(due_date);
CREATE INDEX idx_task_assignments_user ON task_assignments(user_id);

-- Comments
CREATE INDEX idx_comments_task ON comments(task_id);
CREATE INDEX idx_comments_project ON comments(project_id);

-- Notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE read = FALSE;

-- Activity Log
CREATE INDEX idx_activity_org ON activity_log(organization_id);
CREATE INDEX idx_activity_project ON activity_log(project_id);
CREATE INDEX idx_activity_created ON activity_log(created_at DESC);

-- Habits
CREATE INDEX idx_habits_user ON habits(user_id);
CREATE INDEX idx_habit_logs_habit ON habit_logs(habit_id);
CREATE INDEX idx_habit_logs_date ON habit_logs(completed_at);

-- Transactions
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(date);

-- CRM
CREATE INDEX idx_crm_contacts_org ON crm_contacts(organization_id);
CREATE INDEX idx_crm_contacts_assigned ON crm_contacts(assigned_to);
CREATE INDEX idx_crm_deals_org ON crm_deals(organization_id);
CREATE INDEX idx_crm_deals_contact ON crm_deals(contact_id);
CREATE INDEX idx_crm_deals_stage ON crm_deals(stage);
CREATE INDEX idx_crm_tasks_due ON crm_tasks(due_date);
CREATE INDEX idx_crm_communications_contact ON crm_communications(contact_id);

-- Events
CREATE INDEX idx_events_user ON events(user_id);
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_crm_contact ON events(crm_contact_id);

-- Audit
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE savers_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pomodoro_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get current user's organization
CREATE OR REPLACE FUNCTION get_user_org_id()
RETURNS UUID AS $$
    SELECT organization_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if current user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT is_super_admin FROM profiles WHERE id = auth.uid()),
        FALSE
    );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if current user is org admin
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

-- PROFILES
CREATE POLICY "Users can view profiles in same org" ON profiles
    FOR SELECT USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- TEAMS
CREATE POLICY "Users can view teams in org" ON teams
    FOR SELECT USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Admins can manage teams" ON teams
    FOR ALL USING (organization_id = get_user_org_id() AND is_org_admin());

-- PROJECTS
CREATE POLICY "Users can view accessible projects" ON projects
    FOR SELECT USING (
        organization_id = get_user_org_id() AND (
            id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid())
            OR is_org_admin()
        )
        OR is_super_admin()
    );

CREATE POLICY "Project owners/editors can update" ON projects
    FOR UPDATE USING (
        id IN (SELECT project_id FROM project_members WHERE user_id = auth.uid() AND permission IN ('owner', 'editor'))
        OR is_org_admin()
    );

-- TASKS
CREATE POLICY "Users can view tasks in org" ON tasks
    FOR SELECT USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Users can create tasks" ON tasks
    FOR INSERT WITH CHECK (organization_id = get_user_org_id());

CREATE POLICY "Users can update tasks" ON tasks
    FOR UPDATE USING (organization_id = get_user_org_id());

-- NOTIFICATIONS
CREATE POLICY "Users see own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- HABITS
CREATE POLICY "Users manage own habits" ON habits
    FOR ALL USING (user_id = auth.uid());

-- TRANSACTIONS
CREATE POLICY "Users manage own transactions" ON transactions
    FOR ALL USING (user_id = auth.uid() OR is_super_admin());

-- CRM (solo org con feature abilitata)
CREATE POLICY "CRM access" ON crm_contacts
    FOR ALL USING (
        organization_id = get_user_org_id()
        OR is_super_admin()
    );

CREATE POLICY "CRM deals access" ON crm_deals
    FOR ALL USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "CRM quotes access" ON crm_quotes
    FOR ALL USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "CRM tasks access" ON crm_tasks
    FOR ALL USING (organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "CRM communications access" ON crm_communications
    FOR ALL USING (organization_id = get_user_org_id() OR is_super_admin());

-- AUDIT LOG (solo super admin)
CREATE POLICY "Super admin sees all audit" ON audit_log
    FOR SELECT USING (is_super_admin());

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at automatically
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

CREATE TRIGGER update_projects_updated_at 
    BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_crm_contacts_updated_at 
    BEFORE UPDATE ON crm_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_crm_deals_updated_at 
    BEFORE UPDATE ON crm_deals
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
SELECT id, 'Magia Avanzata', 'Illusionismo professionale', '✨' FROM skill_categories WHERE name = 'Tecnica';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Bolle di Sapone', 'Spettacolo bolle giganti', '🫧' FROM skill_categories WHERE name = 'Tecnica';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Vendita', 'Proporre e chiudere contratti', '💰' FROM skill_categories WHERE name = 'Business';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Preventivi', 'Creare preventivi efficaci', '📝' FROM skill_categories WHERE name = 'Business';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Follow-up', 'Gestione post-evento', '📞' FROM skill_categories WHERE name = 'Business';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Gestione Genitori', 'Comunicazione con i genitori', '👨‍👩‍👧' FROM skill_categories WHERE name = 'Relazioni';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Teamwork', 'Collaborazione con colleghi', '👥' FROM skill_categories WHERE name = 'Relazioni';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Problem Solving', 'Gestione imprevisti', '🔧' FROM skill_categories WHERE name = 'Relazioni';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Public Speaking', 'Parlare in pubblico', '🎤' FROM skill_categories WHERE name = 'Crescita';
INSERT INTO skills (category_id, name, description, icon) 
SELECT id, 'Time Management', 'Gestione del tempo', '⏰' FROM skill_categories WHERE name = 'Crescita';

-- Default achievements
INSERT INTO achievements (code, name, description, icon, requirement_type, requirement_value, xp_reward) VALUES
    ('first_habit', 'Prima Abitudine', 'Crea la tua prima abitudine', '🌱', 'habits_created', 1, 10),
    ('week_warrior', 'Guerriero della Settimana', 'Completa tutte le abitudini per 7 giorni', '🔥', 'habit_streak', 7, 50),
    ('month_master', 'Maestro del Mese', 'Mantieni uno streak di 30 giorni', '🏆', 'habit_streak', 30, 200),
    ('task_starter', 'Primo Passo', 'Completa il tuo primo task', '✅', 'tasks_completed', 1, 10),
    ('task_machine', 'Macchina da Task', 'Completa 100 task', '⚡', 'tasks_completed', 100, 100),
    ('bookworm', 'Topo di Biblioteca', 'Leggi 10 libri', '📚', 'books_completed', 10, 150),
    ('early_bird', 'Mattiniero', 'Completa la routine S.A.V.E.R.S. 7 giorni di fila', '🌅', 'savers_streak', 7, 75),
    ('team_player', 'Giocatore di Squadra', 'Partecipa a 5 progetti team', '🤝', 'team_projects', 5, 100),
    ('crm_pro', 'CRM Pro', 'Aggiungi 50 contatti al CRM', '📇', 'crm_contacts', 50, 100),
    ('closer', 'Closer', 'Chiudi 10 trattative vinte', '💰', 'deals_won', 10, 200);

-- ============================================
-- FATTO! Database pronto per SAVERS Pro SaaS
-- ============================================
```

---

# PARTE 3: PROMPT RALPH LOOP

## Istruzioni per Uso

```bash
# 1. Clona/crea progetto
mkdir savers-pro-v2
cd savers-pro-v2
cp /path/to/savers-pro-v5.html ./index.html

# 2. Apri Claude Code
claude

# 3. Installa Ralph (se non fatto)
/plugin install ralph-wiggum@claude-plugins-official

# 4. Esegui i prompt uno alla volta
# Copia-incolla ogni prompt e attendi il completamento
```

---

## FASE 0: Setup Progetto

```
/ralph-loop "
## OBIETTIVO
Setup struttura progetto SAVERS Pro con Supabase Cloud

## CONTESTO
- File esistente: index.html (35k righe, app funzionante)
- Backend target: Supabase Cloud (già creato, credenziali da inserire)
- Deploy: Vercel (frontend) + Supabase (backend)

## TASK

### 1. Struttura cartelle
Crea:
- /css/styles.css (estrai CSS da index.html)
- /js/ (per futuri moduli)
- /.env.example
- /vercel.json
- /.gitignore

### 2. Estrarre CSS
- Copia tutto tra <style> e </style> da index.html
- Salva in /css/styles.css
- Sostituisci nel HTML con: <link rel=\"stylesheet\" href=\"css/styles.css\">

### 3. File configurazione

.env.example:
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

.gitignore:
node_modules/
.env
.env.local
dist/
.DS_Store

vercel.json:
{
  \"version\": 2,
  \"builds\": [
    { \"src\": \"**/*\", \"use\": \"@vercel/static\" }
  ],
  \"routes\": [
    { \"src\": \"/(.*)\", \"dest\": \"/$1\" }
  ]
}

### 4. Aggiungere Supabase Client
Nel <head> di index.html, DOPO Chart.js, aggiungi:

<script src=\"https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2\"></script>
<script>
    // Supabase Configuration
    const SUPABASE_URL = 'URL_DA_SOSTITUIRE';
    const SUPABASE_ANON_KEY = 'KEY_DA_SOSTITUIRE';
    
    // Initialize Supabase Client
    const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    
    console.log('Supabase initialized:', supabase ? 'OK' : 'FAILED');
</script>

### 5. Verifica
- Apri index.html nel browser
- Controlla console: deve mostrare 'Supabase initialized: OK'
- L'app deve funzionare come prima

## CRITERI DI SUCCESSO
- [ ] CSS estratto in file separato
- [ ] Link CSS funzionante
- [ ] Supabase client caricato
- [ ] Console mostra 'Supabase initialized: OK'
- [ ] App funziona normalmente
- [ ] File .env.example creato
- [ ] File vercel.json creato

<promise>FASE0_COMPLETE</promise>
" --max-iterations 20
```

---

## FASE 1: Auth Migration

```
/ralph-loop "
## OBIETTIVO
Migrare autenticazione da Google OAuth diretto a Supabase Auth

## CONTESTO
- App ha già login Google funzionante (client-side)
- Supabase Auth già configurato con Google provider
- Dobbiamo mantenere gli scope per Google Calendar

## TASK

### 1. Sostituire loginWithGoogle()

TROVA la funzione loginWithGoogle() esistente e SOSTITUISCILA con:

async function loginWithGoogle() {
    showToast('Connessione a Google...', 'info');
    
    try {
        const { data, error } = await supabase.auth.signInWithOAuth({
            provider: 'google',
            options: {
                scopes: 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events',
                redirectTo: window.location.origin,
                queryParams: {
                    access_type: 'offline',
                    prompt: 'consent'
                }
            }
        });
        
        if (error) {
            console.error('Login error:', error);
            showToast('Errore login: ' + error.message, 'error');
        }
        // Il redirect avviene automaticamente
    } catch (err) {
        console.error('Login exception:', err);
        showToast('Errore di connessione', 'error');
    }
}

### 2. Aggiungere Auth State Listener

DOPO l'inizializzazione di Supabase, AGGIUNGI:

// Auth State Management
let currentUser = null;

supabase.auth.onAuthStateChange(async (event, session) => {
    console.log('Auth event:', event);
    
    if (event === 'SIGNED_IN' && session) {
        currentUser = session.user;
        console.log('User signed in:', currentUser.email);
        
        // Salva token Google per Calendar API
        if (session.provider_token) {
            localStorage.setItem('google_access_token', session.provider_token);
        }
        if (session.provider_refresh_token) {
            localStorage.setItem('google_refresh_token', session.provider_refresh_token);
        }
        
        // Carica o crea profilo
        await ensureUserProfile();
        
        // Mostra app
        hideLoginScreen();
        await initializeApp();
        
    } else if (event === 'SIGNED_OUT') {
        currentUser = null;
        state = getDefaultState();
        showLoginScreen();
        
    } else if (event === 'TOKEN_REFRESHED' && session) {
        // Aggiorna token Google se presente
        if (session.provider_token) {
            localStorage.setItem('google_access_token', session.provider_token);
        }
    }
});

// Check sessione esistente all'avvio
async function checkExistingSession() {
    const { data: { session } } = await supabase.auth.getSession();
    if (session) {
        currentUser = session.user;
        await ensureUserProfile();
        hideLoginScreen();
        await initializeApp();
    } else {
        showLoginScreen();
    }
}

### 3. Creare ensureUserProfile()

async function ensureUserProfile() {
    if (!currentUser) return;
    
    // Cerca profilo esistente
    let { data: profile, error } = await supabase
        .from('profiles')
        .select('*, organization:organizations(*)')
        .eq('id', currentUser.id)
        .single();
    
    if (error && error.code === 'PGRST116') {
        // Nuovo utente - crea organizzazione e profilo
        console.log('Creating new user profile...');
        
        // 1. Crea organizzazione
        const { data: org, error: orgError } = await supabase
            .from('organizations')
            .insert({
                name: (currentUser.user_metadata?.full_name || currentUser.email.split('@')[0]) + \"'s Workspace\",
                owner_id: currentUser.id
            })
            .select()
            .single();
        
        if (orgError) {
            console.error('Error creating org:', orgError);
            showToast('Errore creazione account', 'error');
            return;
        }
        
        // 2. Crea profilo
        const { data: newProfile, error: profileError } = await supabase
            .from('profiles')
            .insert({
                id: currentUser.id,
                organization_id: org.id,
                email: currentUser.email,
                full_name: currentUser.user_metadata?.full_name || currentUser.email.split('@')[0],
                avatar_url: currentUser.user_metadata?.avatar_url,
                org_role: 'owner'
            })
            .select('*, organization:organizations(*)')
            .single();
        
        if (profileError) {
            console.error('Error creating profile:', profileError);
            showToast('Errore creazione profilo', 'error');
            return;
        }
        
        // 3. Aggiorna owner_id nell'organizzazione
        await supabase
            .from('organizations')
            .update({ owner_id: currentUser.id })
            .eq('id', org.id);
        
        profile = newProfile;
        showToast('Benvenuto in SAVERS Pro! 🎉', 'success');
    }
    
    // Salva in state
    state.profile = profile;
    state.organization = profile.organization;
    state.organizationId = profile.organization_id;
    
    // Aggiorna UI profilo
    updateProfileUI();
    
    console.log('Profile loaded:', profile.full_name);
}

function updateProfileUI() {
    if (!state.profile) return;
    
    // Aggiorna avatar
    const avatarEls = document.querySelectorAll('.profile-avatar');
    avatarEls.forEach(el => {
        if (state.profile.avatar_url) {
            el.innerHTML = '<img src=\"' + state.profile.avatar_url + '\" alt=\"Avatar\" style=\"width:100%;height:100%;object-fit:cover;border-radius:50%;\">';
        } else {
            el.textContent = state.profile.full_name?.charAt(0)?.toUpperCase() || '?';
        }
    });
    
    // Aggiorna nome dove mostrato
    const nameEls = document.querySelectorAll('.profile-name, #profileName, #userName');
    nameEls.forEach(el => {
        el.textContent = state.profile.full_name || 'Utente';
    });
}

### 4. Modificare logout()

TROVA la funzione logout() e SOSTITUISCILA con:

async function logout() {
    if (!confirm('Sei sicuro di voler uscire?')) return;
    
    try {
        await supabase.auth.signOut();
        
        // Pulisci stato
        currentUser = null;
        state = getDefaultState();
        
        // Pulisci localStorage tokens
        localStorage.removeItem('google_access_token');
        localStorage.removeItem('google_refresh_token');
        
        showLoginScreen();
        showToast('Logout effettuato', 'info');
        
    } catch (error) {
        console.error('Logout error:', error);
        showToast('Errore logout', 'error');
    }
}

### 5. Modificare inizializzazione app

TROVA dove viene chiamato checkSavedLogin() o simile all'avvio
SOSTITUISCI con chiamata a checkExistingSession()

Nel DOMContentLoaded o dove inizializzi l'app:
// Invece di checkSavedLogin() o initGoogleAPI()
checkExistingSession();

### 6. Rimuovere vecchio codice Google (opzionale, dopo test)
Commenta (non eliminare) le vecchie funzioni Google OAuth:
- initGoogleAPI()
- initGoogleIdentity()
- handleGoogleAuthResponse()
- Vecchio loginWithGoogle()

## CRITERI DI SUCCESSO
- [ ] Click su 'Login con Google' reindirizza a Google
- [ ] Dopo login, ritorna all'app loggato
- [ ] Profilo creato in Supabase (verifica in dashboard)
- [ ] Organizzazione creata in Supabase
- [ ] Session persiste al refresh pagina
- [ ] Logout funziona
- [ ] Console non mostra errori

<promise>FASE1_AUTH_COMPLETE</promise>
" --max-iterations 35
```

---

## FASE 2: Migrazione Dati Personali

```
/ralph-loop "
## OBIETTIVO
Migrare tutti i moduli dati personali da localStorage a Supabase

## MODULI DA MIGRARE
1. Habits + Habit Logs
2. Transactions (Finance)
3. Tasks personali (non di progetto)
4. Skills + User Skills
5. Books
6. Goals
7. SAVERS Logs
8. Notes
9. Pomodoro Sessions
10. Events (calendario personale)

## PATTERN DA USARE PER OGNI MODULO

Per ogni modulo, crea queste funzioni:

### Template Load
async function load[Module]FromDB() {
    if (!currentUser) return [];
    
    const { data, error } = await supabase
        .from('[table_name]')
        .select('*')
        .eq('user_id', currentUser.id)
        .order('created_at', { ascending: false });
    
    if (error) {
        console.error('Error loading [module]:', error);
        return state.[module] || []; // Fallback a state locale
    }
    
    return data || [];
}

### Template Save
async function save[Module]ToDB(item) {
    if (!currentUser) return null;
    
    const { data, error } = await supabase
        .from('[table_name]')
        .insert({
            user_id: currentUser.id,
            organization_id: state.organizationId,
            ...item
        })
        .select()
        .single();
    
    if (error) {
        console.error('Error saving [module]:', error);
        showToast('Errore salvataggio', 'error');
        return null;
    }
    
    return data;
}

### Template Update
async function update[Module]InDB(id, updates) {
    const { error } = await supabase
        .from('[table_name]')
        .update(updates)
        .eq('id', id)
        .eq('user_id', currentUser.id);
    
    if (error) {
        console.error('Error updating [module]:', error);
        return false;
    }
    return true;
}

### Template Delete
async function delete[Module]FromDB(id) {
    const { error } = await supabase
        .from('[table_name]')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser.id);
    
    if (error) {
        console.error('Error deleting [module]:', error);
        return false;
    }
    return true;
}

### Template Migrazione
async function migrate[Module]FromLocalStorage() {
    const localKey = '[localStorage_key]';
    const localData = JSON.parse(localStorage.getItem(localKey) || '[]');
    
    if (localData.length === 0) return;
    
    console.log('Migrating [module]:', localData.length, 'items');
    
    for (const item of localData) {
        await supabase.from('[table_name]').upsert({
            user_id: currentUser.id,
            organization_id: state.organizationId,
            // mappa i campi...
        }, { onConflict: 'user_id,id' });
    }
    
    localStorage.removeItem(localKey);
    showToast('[Module] migrati!', 'success');
}

## TASK SPECIFICI

### 1. HABITS
- Tabella: habits
- localStorage key: 'habits' o simile
- Campi: name, icon, frequency, department, current_streak, best_streak

### 2. HABIT_LOGS
- Tabella: habit_logs
- localStorage key: 'habitLogs' o 'habitCompletions'
- Campi: habit_id, completed_at

### 3. TRANSACTIONS
- Tabella: transactions
- localStorage key: 'transactions' o 'finance'
- Campi: type, amount, description, category, date, department

### 4. TASKS (personali)
- Tabella: tasks (con project_id = NULL)
- localStorage key: 'tasks'
- Campi: title, description, status, priority, due_date, quadrant, category

### 5. USER_SKILLS
- Tabella: user_skills
- localStorage key: 'userSkills' o 'skills'
- Campi: skill_id, xp

### 6. BOOKS
- Tabella: books
- localStorage key: 'books'
- Campi: title, author, status, pages_total, pages_read, rating

### 7. GOALS
- Tabella: goals
- localStorage key: 'goals'
- Campi: title, type, timeframe, target_value, current_value, due_date

### 8. SAVERS_LOGS
- Tabella: savers_logs
- localStorage key: 'saversLogs' o 'routineLogs'
- Campi: date, silence_completed, affirmations_completed, etc.

### 9. NOTES
- Tabella: notes
- localStorage key: 'notes'
- Campi: title, content, color, is_pinned, tags

### 10. POMODORO_SESSIONS
- Tabella: pomodoro_sessions
- localStorage key: 'pomodoroSessions' o 'focusSessions'
- Campi: started_at, ended_at, duration_minutes, type, completed

## INTEGRAZIONE CON UI

Per ogni modulo, TROVA le funzioni esistenti che:
- Caricano dati (es: loadHabits, renderHabits)
- Salvano dati (es: saveHabit, addHabit)
- Aggiornano dati (es: toggleHabit, updateHabit)
- Eliminano dati (es: deleteHabit)

E MODIFICALE per usare le nuove funzioni Supabase.

Esempio per Habits:
// PRIMA
function loadHabits() {
    return JSON.parse(localStorage.getItem('habits') || '[]');
}

// DOPO
async function loadHabits() {
    state.habits = await loadHabitsFromDB();
    return state.habits;
}

## MIGRAZIONE ALL'AVVIO

In ensureUserProfile(), dopo aver caricato il profilo, aggiungi:
// Migra dati da localStorage se presenti
await migrateAllFromLocalStorage();

async function migrateAllFromLocalStorage() {
    await migrateHabitsFromLocalStorage();
    await migrateTransactionsFromLocalStorage();
    await migrateTasksFromLocalStorage();
    await migrateSkillsFromLocalStorage();
    await migrateBooksFromLocalStorage();
    await migrateGoalsFromLocalStorage();
    await migrateSaversLogsFromLocalStorage();
    await migrateNotesFromLocalStorage();
    await migratePomodoroFromLocalStorage();
}

## CRITERI DI SUCCESSO
- [ ] Habits salvati e caricati da Supabase
- [ ] Transactions salvate e caricate da Supabase
- [ ] Tasks personali salvati e caricati da Supabase
- [ ] Skills/XP salvati e caricati da Supabase
- [ ] Books salvati e caricati da Supabase
- [ ] Goals salvati e caricati da Supabase
- [ ] SAVERS logs salvati e caricati da Supabase
- [ ] Notes salvate e caricate da Supabase
- [ ] Pomodoro sessions salvate e caricate da Supabase
- [ ] Migrazione da localStorage funziona
- [ ] UI funziona identica a prima
- [ ] Dati persistono tra sessioni/dispositivi

<promise>FASE2_PERSONAL_DATA_COMPLETE</promise>
" --max-iterations 60
```

---

## FASE 3: Team & Progetti

```
/ralph-loop "
## OBIETTIVO
Implementare backend reale per Team e Progetti collaborativi

## CONTESTO
- UI Team e Kanban già esistente
- Deve funzionare multi-utente
- Permessi: owner, editor, viewer

## TASK

### 1. GESTIONE TEAM

// Carica i miei team
async function loadMyTeams() {
    const { data, error } = await supabase
        .from('team_members')
        .select(\`
            team_id,
            role,
            team:teams(
                id, name, description, color, icon,
                organization_id,
                created_by,
                members:team_members(
                    user_id,
                    role,
                    profile:profiles(id, full_name, avatar_url, email)
                )
            )
        \`)
        .eq('user_id', currentUser.id);
    
    if (error) {
        console.error('Error loading teams:', error);
        return [];
    }
    
    return data?.map(tm => ({
        ...tm.team,
        myRole: tm.role,
        memberCount: tm.team.members?.length || 0
    })) || [];
}

// Crea team
async function createTeam(teamData) {
    // Crea team
    const { data: team, error } = await supabase
        .from('teams')
        .insert({
            organization_id: state.organizationId,
            name: teamData.name,
            description: teamData.description || '',
            color: teamData.color || '#6366f1',
            icon: teamData.icon || '👥',
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        console.error('Error creating team:', error);
        showToast('Errore creazione team', 'error');
        return null;
    }
    
    // Aggiungi creatore come leader
    await supabase.from('team_members').insert({
        team_id: team.id,
        user_id: currentUser.id,
        role: 'leader'
    });
    
    showToast('Team creato! 🎉', 'success');
    return team;
}

// Aggiungi membro al team
async function addTeamMember(teamId, email, role = 'member') {
    // Trova utente per email
    const { data: profile } = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('email', email)
        .eq('organization_id', state.organizationId)
        .single();
    
    if (!profile) {
        showToast('Utente non trovato nell\\'organizzazione', 'error');
        return false;
    }
    
    // Aggiungi al team
    const { error } = await supabase
        .from('team_members')
        .insert({
            team_id: teamId,
            user_id: profile.id,
            role: role
        });
    
    if (error) {
        if (error.code === '23505') {
            showToast('Utente già nel team', 'warning');
        } else {
            showToast('Errore aggiunta membro', 'error');
        }
        return false;
    }
    
    // Notifica
    await createNotification(profile.id, 'team_invite',
        'Sei stato aggiunto al team ' + (await getTeamName(teamId)),
        null
    );
    
    showToast(profile.full_name + ' aggiunto al team!', 'success');
    return true;
}

### 2. GESTIONE PROGETTI

// Carica progetti accessibili
async function loadProjects(teamId = null) {
    let query = supabase
        .from('projects')
        .select(\`
            *,
            team:teams(id, name, color),
            created_by_profile:profiles!projects_created_by_fkey(full_name, avatar_url),
            members:project_members(
                user_id,
                permission,
                profile:profiles(id, full_name, avatar_url)
            )
        \`)
        .eq('organization_id', state.organizationId)
        .neq('status', 'archived')
        .order('updated_at', { ascending: false });
    
    if (teamId) {
        query = query.eq('team_id', teamId);
    }
    
    const { data, error } = await query;
    
    if (error) {
        console.error('Error loading projects:', error);
        return [];
    }
    
    // Filtra solo progetti dove ho accesso (o sono admin org)
    return data?.filter(p => 
        p.members?.some(m => m.user_id === currentUser.id) ||
        state.profile.org_role === 'owner' ||
        state.profile.org_role === 'admin'
    ) || [];
}

// Crea progetto
async function createProject(projectData) {
    const { data: project, error } = await supabase
        .from('projects')
        .insert({
            organization_id: state.organizationId,
            team_id: projectData.teamId || null,
            name: projectData.name,
            description: projectData.description || '',
            objective: projectData.objective || '',
            color: projectData.color || '#10b981',
            start_date: projectData.startDate || null,
            due_date: projectData.dueDate || null,
            budget_estimated: projectData.budget || 0,
            status: 'planning',
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        console.error('Error creating project:', error);
        showToast('Errore creazione progetto', 'error');
        return null;
    }
    
    // Aggiungi creatore come owner
    await supabase.from('project_members').insert({
        project_id: project.id,
        user_id: currentUser.id,
        permission: 'owner',
        added_by: currentUser.id
    });
    
    // Log attività
    await logActivity('project_created', 'project', project.id, {
        name: project.name
    });
    
    showToast('Progetto creato! 🎯', 'success');
    return project;
}

// Verifica permesso
async function checkProjectPermission(projectId, required = 'viewer') {
    // Super admin o org admin hanno sempre accesso
    if (state.profile.is_super_admin || 
        state.profile.org_role === 'owner' || 
        state.profile.org_role === 'admin') {
        return true;
    }
    
    const { data } = await supabase
        .from('project_members')
        .select('permission')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();
    
    if (!data) return false;
    
    const levels = { viewer: 1, editor: 2, owner: 3 };
    return levels[data.permission] >= levels[required];
}

### 3. TASK COLLABORATIVI

// Carica task del progetto
async function loadProjectTasks(projectId) {
    const { data, error } = await supabase
        .from('tasks')
        .select(\`
            *,
            created_by_profile:profiles!tasks_created_by_fkey(full_name, avatar_url),
            assignments:task_assignments(
                user_id,
                profile:profiles(id, full_name, avatar_url)
            ),
            checklist:task_checklist(id, title, completed, position)
        \`)
        .eq('project_id', projectId)
        .order('position', { ascending: true });
    
    if (error) {
        console.error('Error loading tasks:', error);
        return [];
    }
    
    return data || [];
}

// Crea task nel progetto
async function createProjectTask(projectId, taskData) {
    // Verifica permesso editor
    if (!await checkProjectPermission(projectId, 'editor')) {
        showToast('Non hai i permessi per aggiungere task', 'error');
        return null;
    }
    
    const { data: task, error } = await supabase
        .from('tasks')
        .insert({
            organization_id: state.organizationId,
            project_id: projectId,
            title: taskData.title,
            description: taskData.description || '',
            status: taskData.status || 'todo',
            priority: taskData.priority || 'medium',
            due_date: taskData.dueDate || null,
            created_by: currentUser.id,
            position: taskData.position || 0
        })
        .select()
        .single();
    
    if (error) {
        console.error('Error creating task:', error);
        showToast('Errore creazione task', 'error');
        return null;
    }
    
    // Assegna utenti
    if (taskData.assignees?.length > 0) {
        for (const userId of taskData.assignees) {
            await supabase.from('task_assignments').insert({
                task_id: task.id,
                user_id: userId,
                assigned_by: currentUser.id
            });
            
            // Notifica
            if (userId !== currentUser.id) {
                await createNotification(userId, 'assignment',
                    'Ti è stato assegnato: ' + task.title,
                    '/team?project=' + projectId
                );
            }
        }
    }
    
    // Log attività
    await logActivity('task_created', 'task', task.id, {
        title: task.title,
        project_id: projectId
    });
    
    return task;
}

// Aggiorna status task (drag & drop Kanban)
async function updateTaskStatus(taskId, newStatus, newPosition) {
    const { data: task } = await supabase
        .from('tasks')
        .select('project_id, title, status')
        .eq('id', taskId)
        .single();
    
    if (!task) return false;
    
    // Verifica permesso
    if (!await checkProjectPermission(task.project_id, 'editor')) {
        showToast('Non hai i permessi', 'error');
        return false;
    }
    
    const oldStatus = task.status;
    
    const updates = { 
        status: newStatus,
        position: newPosition || 0
    };
    
    if (newStatus === 'done' && oldStatus !== 'done') {
        updates.completed_at = new Date().toISOString();
    } else if (newStatus !== 'done') {
        updates.completed_at = null;
    }
    
    const { error } = await supabase
        .from('tasks')
        .update(updates)
        .eq('id', taskId);
    
    if (error) {
        console.error('Error updating task:', error);
        return false;
    }
    
    // Log se status cambiato
    if (oldStatus !== newStatus) {
        await logActivity('task_status_changed', 'task', taskId, {
            title: task.title,
            from: oldStatus,
            to: newStatus,
            project_id: task.project_id
        });
    }
    
    return true;
}

### 4. COMMENTI

// Carica commenti
async function loadComments(entityType, entityId) {
    const column = entityType === 'task' ? 'task_id' : 'project_id';
    
    const { data, error } = await supabase
        .from('comments')
        .select(\`
            *,
            user:profiles(id, full_name, avatar_url)
        \`)
        .eq(column, entityId)
        .order('created_at', { ascending: true });
    
    if (error) {
        console.error('Error loading comments:', error);
        return [];
    }
    
    return data || [];
}

// Aggiungi commento
async function addComment(entityType, entityId, content) {
    // Parse menzioni @nome
    const mentionRegex = /@([\\w\\s]+?)(?=\\s|@|$)/g;
    const mentionMatches = [...content.matchAll(mentionRegex)];
    const mentionNames = mentionMatches.map(m => m[1].trim());
    
    let mentionIds = [];
    if (mentionNames.length > 0) {
        const { data: profiles } = await supabase
            .from('profiles')
            .select('id, full_name')
            .eq('organization_id', state.organizationId)
            .in('full_name', mentionNames);
        
        mentionIds = profiles?.map(p => p.id) || [];
    }
    
    const commentData = {
        organization_id: state.organizationId,
        user_id: currentUser.id,
        content: content,
        mentions: mentionIds
    };
    
    if (entityType === 'task') {
        commentData.task_id = entityId;
    } else {
        commentData.project_id = entityId;
    }
    
    const { data: comment, error } = await supabase
        .from('comments')
        .insert(commentData)
        .select(\`*, user:profiles(full_name, avatar_url)\`)
        .single();
    
    if (error) {
        console.error('Error adding comment:', error);
        showToast('Errore invio commento', 'error');
        return null;
    }
    
    // Notifica menzionati
    for (const userId of mentionIds) {
        if (userId !== currentUser.id) {
            await createNotification(userId, 'mention',
                state.profile.full_name + ' ti ha menzionato in un commento',
                '/' + entityType + 's/' + entityId
            );
        }
    }
    
    return comment;
}

### 5. ACTIVITY LOG

async function logActivity(action, entityType, entityId, details) {
    await supabase.from('activity_log').insert({
        organization_id: state.organizationId,
        project_id: details?.project_id || null,
        task_id: entityType === 'task' ? entityId : null,
        user_id: currentUser.id,
        action: action,
        entity_type: entityType,
        entity_id: entityId,
        details: details
    });
}

async function loadProjectActivity(projectId, limit = 20) {
    const { data } = await supabase
        .from('activity_log')
        .select(\`
            *,
            user:profiles(full_name, avatar_url)
        \`)
        .eq('project_id', projectId)
        .order('created_at', { ascending: false })
        .limit(limit);
    
    return data || [];
}

### 6. NOTIFICHE

async function createNotification(userId, type, title, link = null, body = null) {
    await supabase.from('notifications').insert({
        user_id: userId,
        organization_id: state.organizationId,
        type: type,
        title: title,
        body: body,
        link: link,
        actor_id: currentUser.id
    });
}

### 7. INTEGRARE CON UI ESISTENTE

Trova e aggiorna tutte le funzioni nella sezione Team/Progetti:
- renderMyTeams() → usa loadMyTeams()
- renderTeamProjects() → usa loadProjects()
- renderKanban() → usa loadProjectTasks()
- saveTeamTask() → usa createProjectTask()
- dropTask() → usa updateTaskStatus()
- renderComments() → usa loadComments()
- postComment() → usa addComment()
- renderActivityLog() → usa loadProjectActivity()

## CRITERI DI SUCCESSO
- [ ] Creazione team funziona
- [ ] Membri team visibili
- [ ] Creazione progetto funziona
- [ ] Permessi progetto rispettati
- [ ] Task creati e salvati in DB
- [ ] Drag & drop Kanban aggiorna DB
- [ ] Commenti funzionano
- [ ] Activity log popolato
- [ ] Notifiche create

<promise>FASE3_TEAM_PROJECTS_COMPLETE</promise>
" --max-iterations 70
```

---

## FASE 4: Realtime + Notifiche

```
/ralph-loop "
## OBIETTIVO
Implementare aggiornamenti in tempo reale e sistema notifiche

## TASK

### 1. REALTIME SUBSCRIPTIONS

// Setup all'avvio dopo login
function setupRealtimeSubscriptions() {
    // Notifiche personali
    supabase
        .channel('my-notifications')
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: 'user_id=eq.' + currentUser.id
        }, handleNewNotification)
        .subscribe();
    
    console.log('Realtime notifications subscribed');
}

function handleNewNotification(payload) {
    const notification = payload.new;
    
    // Aggiorna badge
    updateNotificationBadge();
    
    // Toast
    showToast('🔔 ' + notification.title, 'info');
    
    // Suono
    if (state.profile?.notification_sound) {
        playNotificationSound();
    }
    
    // Browser notification
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(notification.title, {
            body: notification.body || '',
            icon: '/icon-192.png'
        });
    }
}

async function updateNotificationBadge() {
    const { count } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', currentUser.id)
        .eq('read', false);
    
    const badge = document.getElementById('notificationBadge');
    if (badge) {
        if (count && count > 0) {
            badge.textContent = count > 99 ? '99+' : count;
            badge.style.display = 'flex';
        } else {
            badge.style.display = 'none';
        }
    }
}

// Realtime per progetto corrente
let currentProjectChannel = null;

function subscribeToProject(projectId) {
    // Unsubscribe da precedente
    if (currentProjectChannel) {
        supabase.removeChannel(currentProjectChannel);
    }
    
    currentProjectChannel = supabase
        .channel('project-' + projectId)
        .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: 'tasks',
            filter: 'project_id=eq.' + projectId
        }, handleTaskRealtimeChange)
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'comments',
            filter: 'project_id=eq.' + projectId
        }, handleNewProjectComment)
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'activity_log',
            filter: 'project_id=eq.' + projectId
        }, handleNewActivity)
        .subscribe();
    
    console.log('Subscribed to project:', projectId);
}

function handleTaskRealtimeChange(payload) {
    // Ignora se sono io (evita doppio update)
    // Non possiamo verificare chi ha fatto la modifica senza updated_by
    // Quindi aggiorniamo sempre l'UI
    
    const task = payload.new || payload.old;
    
    switch (payload.eventType) {
        case 'INSERT':
            // Aggiungi task al Kanban se non già presente
            addTaskToKanbanIfNew(payload.new);
            break;
        case 'UPDATE':
            // Aggiorna task nel Kanban
            updateTaskInKanban(payload.new);
            break;
        case 'DELETE':
            // Rimuovi task dal Kanban
            removeTaskFromKanban(payload.old.id);
            break;
    }
}

function handleNewProjectComment(payload) {
    const comment = payload.new;
    
    // Se è nel task attualmente visualizzato, aggiungi alla lista
    if (state.currentViewingTaskId === comment.task_id) {
        appendCommentToList(comment);
    }
}

function handleNewActivity(payload) {
    // Aggiorna activity feed se visibile
    prependActivityToFeed(payload.new);
}

### 2. BADGE NOTIFICHE NELL'UI

Aggiungi badge nel header o bottom nav:

<div id=\"notificationBadge\" style=\"
    position: absolute;
    top: -5px;
    right: -5px;
    background: #ef4444;
    color: white;
    border-radius: 50%;
    width: 18px;
    height: 18px;
    font-size: 10px;
    display: none;
    align-items: center;
    justify-content: center;
    font-weight: bold;
\">0</div>

### 3. PANNELLO NOTIFICHE

async function loadNotifications() {
    const { data } = await supabase
        .from('notifications')
        .select(\`
            *,
            actor:profiles!notifications_actor_id_fkey(full_name, avatar_url)
        \`)
        .eq('user_id', currentUser.id)
        .order('created_at', { ascending: false })
        .limit(50);
    
    return data || [];
}

async function markNotificationRead(notificationId) {
    await supabase
        .from('notifications')
        .update({ read: true, read_at: new Date().toISOString() })
        .eq('id', notificationId);
    
    updateNotificationBadge();
}

async function markAllNotificationsRead() {
    await supabase
        .from('notifications')
        .update({ read: true, read_at: new Date().toISOString() })
        .eq('user_id', currentUser.id)
        .eq('read', false);
    
    updateNotificationBadge();
}

function renderNotifications(notifications) {
    return notifications.map(n => \`
        <div class=\"notification-item \${n.read ? '' : 'unread'}\" 
             onclick=\"handleNotificationClick('\${n.id}', '\${n.link || ''}')\">
            <div class=\"notification-icon\">\${getNotificationIcon(n.type)}</div>
            <div class=\"notification-content\">
                <div class=\"notification-title\">\${n.title}</div>
                \${n.body ? '<div class=\"notification-body\">' + n.body + '</div>' : ''}
                <div class=\"notification-time\">\${formatTimeAgo(n.created_at)}</div>
            </div>
        </div>
    \`).join('');
}

function getNotificationIcon(type) {
    const icons = {
        'mention': '💬',
        'assignment': '📋',
        'deadline': '⏰',
        'comment': '💬',
        'team_invite': '👥',
        'achievement': '🏆',
        'crm_reminder': '📞',
        'system': 'ℹ️'
    };
    return icons[type] || '🔔';
}

async function handleNotificationClick(notificationId, link) {
    await markNotificationRead(notificationId);
    
    if (link) {
        // Naviga alla pagina relativa
        // Implementa navigazione basata sul link
    }
    
    closeModal('notificationsModal');
}

### 4. RICHIESTA PERMESSO BROWSER NOTIFICATIONS

async function requestNotificationPermission() {
    if (!('Notification' in window)) return;
    
    if (Notification.permission === 'default') {
        const permission = await Notification.requestPermission();
        console.log('Notification permission:', permission);
    }
}

// Chiama in initializeApp()

### 5. SUONO NOTIFICA

function playNotificationSound() {
    try {
        const audio = new Audio('data:audio/wav;base64,UklGRl9vT19...');
        // Oppure usa un URL: new Audio('/sounds/notification.mp3');
        audio.volume = 0.3;
        audio.play().catch(() => {}); // Ignora errori autoplay
    } catch (e) {}
}

### 6. INTEGRAZIONE

In checkExistingSession() o dopo login:
setupRealtimeSubscriptions();
requestNotificationPermission();
updateNotificationBadge();

Quando si apre un progetto:
subscribeToProject(projectId);

## CRITERI DI SUCCESSO
- [ ] Notifiche arrivano in realtime
- [ ] Badge si aggiorna automaticamente
- [ ] Toast appare per nuove notifiche
- [ ] Task Kanban si aggiorna in realtime
- [ ] Commenti appaiono in realtime
- [ ] Activity feed si aggiorna
- [ ] Browser notification funziona (se permesso)

<promise>FASE4_REALTIME_COMPLETE</promise>
" --max-iterations 40
```

---

## FASE 5: CRM Premium

```
/ralph-loop "
## OBIETTIVO
Implementare modulo CRM completo per piani Pro/Business

## CONTESTO
- Tabelle già create: crm_contacts, crm_deals, crm_quotes, crm_tasks, crm_communications, crm_templates
- Feature disponibile solo per piani pro e business
- Pipeline vendite stile Kanban

## TASK

### 1. CHECK FEATURE ABILITATA

function hasCRMAccess() {
    const plan = state.organization?.plan || 'free';
    return ['pro', 'business', 'enterprise'].includes(plan);
}

// Usa prima di ogni operazione CRM
if (!hasCRMAccess()) {
    showUpgradeModal('Il CRM è disponibile nei piani Pro e Business');
    return;
}

### 2. CONTATTI

// Carica contatti
async function loadCRMContacts(filters = {}) {
    let query = supabase
        .from('crm_contacts')
        .select(\`
            *,
            assigned_to_profile:profiles!crm_contacts_assigned_to_fkey(full_name, avatar_url)
        \`)
        .eq('organization_id', state.organizationId)
        .order('updated_at', { ascending: false });
    
    if (filters.search) {
        query = query.or(\`first_name.ilike.%\${filters.search}%,last_name.ilike.%\${filters.search}%,email.ilike.%\${filters.search}%,phone.ilike.%\${filters.search}%\`);
    }
    if (filters.type) {
        query = query.eq('type', filters.type);
    }
    if (filters.status) {
        query = query.eq('status', filters.status);
    }
    if (filters.assigned_to) {
        query = query.eq('assigned_to', filters.assigned_to);
    }
    
    const { data, error } = await query.limit(100);
    
    if (error) {
        console.error('Error loading contacts:', error);
        return [];
    }
    
    return data || [];
}

// Crea contatto
async function createCRMContact(contactData) {
    const { data, error } = await supabase
        .from('crm_contacts')
        .insert({
            organization_id: state.organizationId,
            first_name: contactData.firstName,
            last_name: contactData.lastName || '',
            email: contactData.email || null,
            phone: contactData.phone || null,
            type: contactData.type || 'private',
            company_name: contactData.companyName || null,
            address: contactData.address || null,
            city: contactData.city || null,
            source: contactData.source || null,
            tags: contactData.tags || [],
            notes: contactData.notes || null,
            children: contactData.children || null,
            assigned_to: contactData.assignedTo || currentUser.id,
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        showToast('Errore creazione contatto', 'error');
        return null;
    }
    
    showToast('Contatto creato! 📇', 'success');
    return data;
}

// Dettaglio contatto
async function loadContactDetail(contactId) {
    const { data } = await supabase
        .from('crm_contacts')
        .select(\`
            *,
            assigned_to_profile:profiles!crm_contacts_assigned_to_fkey(full_name, avatar_url),
            deals:crm_deals(*),
            communications:crm_communications(*, user:profiles(full_name)),
            tasks:crm_tasks(*)
        \`)
        .eq('id', contactId)
        .single();
    
    return data;
}

### 3. PIPELINE (DEALS)

const DEAL_STAGES = [
    { id: 'new', name: 'Nuovo', color: '#6366f1', icon: '📥' },
    { id: 'contacted', name: 'Contattato', color: '#8b5cf6', icon: '📞' },
    { id: 'quote_sent', name: 'Preventivo Inviato', color: '#f59e0b', icon: '📄' },
    { id: 'negotiation', name: 'Trattativa', color: '#3b82f6', icon: '🤝' },
    { id: 'won', name: 'Vinto', color: '#10b981', icon: '🎉' },
    { id: 'lost', name: 'Perso', color: '#ef4444', icon: '❌' }
];

// Carica pipeline
async function loadCRMPipeline(filters = {}) {
    let query = supabase
        .from('crm_deals')
        .select(\`
            *,
            contact:crm_contacts(first_name, last_name, email, phone),
            assigned_to_profile:profiles!crm_deals_assigned_to_fkey(full_name, avatar_url)
        \`)
        .eq('organization_id', state.organizationId)
        .not('stage', 'in', '(won,lost)') // Escludi chiuse per pipeline
        .order('updated_at', { ascending: false });
    
    const { data, error } = await query;
    
    if (error) {
        console.error('Error loading pipeline:', error);
        return [];
    }
    
    // Raggruppa per stage
    const pipeline = {};
    DEAL_STAGES.forEach(s => {
        pipeline[s.id] = data?.filter(d => d.stage === s.id) || [];
    });
    
    return pipeline;
}

// Crea trattativa
async function createCRMDeal(dealData) {
    const { data, error } = await supabase
        .from('crm_deals')
        .insert({
            organization_id: state.organizationId,
            contact_id: dealData.contactId,
            title: dealData.title,
            description: dealData.description || '',
            stage: 'new',
            value: dealData.value || 0,
            event_date: dealData.eventDate || null,
            event_type: dealData.eventType || null,
            expected_close_date: dealData.expectedCloseDate || null,
            assigned_to: dealData.assignedTo || currentUser.id,
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        showToast('Errore creazione trattativa', 'error');
        return null;
    }
    
    showToast('Trattativa creata! 💼', 'success');
    return data;
}

// Sposta deal (drag & drop)
async function updateDealStage(dealId, newStage) {
    const updates = { stage: newStage };
    
    if (newStage === 'won' || newStage === 'lost') {
        updates.closed_at = new Date().toISOString();
    }
    
    const { error } = await supabase
        .from('crm_deals')
        .update(updates)
        .eq('id', dealId);
    
    if (error) {
        showToast('Errore aggiornamento', 'error');
        return false;
    }
    
    return true;
}

### 4. PREVENTIVI

async function createCRMQuote(quoteData) {
    // Genera numero preventivo
    const quoteNumber = await generateQuoteNumber();
    
    // Calcola totali
    const subtotal = quoteData.items.reduce((sum, item) => 
        sum + (item.quantity * item.unit_price), 0);
    const discountAmount = subtotal * (quoteData.discountPercent || 0) / 100;
    const afterDiscount = subtotal - discountAmount;
    const taxAmount = afterDiscount * (quoteData.taxPercent || 0) / 100;
    const total = afterDiscount + taxAmount;
    
    const { data, error } = await supabase
        .from('crm_quotes')
        .insert({
            organization_id: state.organizationId,
            deal_id: quoteData.dealId || null,
            contact_id: quoteData.contactId,
            quote_number: quoteNumber,
            title: quoteData.title,
            issue_date: new Date().toISOString().split('T')[0],
            valid_until: quoteData.validUntil || null,
            event_date: quoteData.eventDate || null,
            items: quoteData.items,
            subtotal: subtotal,
            discount_percent: quoteData.discountPercent || 0,
            discount_amount: discountAmount,
            tax_percent: quoteData.taxPercent || 0,
            tax_amount: taxAmount,
            total: total,
            terms: quoteData.terms || '',
            notes: quoteData.notes || '',
            status: 'draft',
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        showToast('Errore creazione preventivo', 'error');
        return null;
    }
    
    return data;
}

async function generateQuoteNumber() {
    const year = new Date().getFullYear();
    const { count } = await supabase
        .from('crm_quotes')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', state.organizationId)
        .gte('created_at', year + '-01-01');
    
    const num = (count || 0) + 1;
    return 'PRV-' + year + '-' + String(num).padStart(3, '0');
}

### 5. FOLLOW-UP / TASKS CRM

async function loadCRMTasks(filters = {}) {
    let query = supabase
        .from('crm_tasks')
        .select(\`
            *,
            contact:crm_contacts(first_name, last_name),
            deal:crm_deals(title),
            assigned_to_profile:profiles!crm_tasks_assigned_to_fkey(full_name)
        \`)
        .eq('organization_id', state.organizationId)
        .eq('status', 'pending')
        .order('due_date', { ascending: true });
    
    if (filters.assignedTo) {
        query = query.eq('assigned_to', filters.assignedTo);
    }
    
    const { data } = await query;
    return data || [];
}

async function createCRMTask(taskData) {
    const { data, error } = await supabase
        .from('crm_tasks')
        .insert({
            organization_id: state.organizationId,
            contact_id: taskData.contactId || null,
            deal_id: taskData.dealId || null,
            title: taskData.title,
            description: taskData.description || '',
            type: taskData.type || 'call',
            priority: taskData.priority || 'medium',
            due_date: taskData.dueDate,
            due_time: taskData.dueTime || null,
            reminder_at: taskData.reminderAt || null,
            assigned_to: taskData.assignedTo || currentUser.id,
            created_by: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        showToast('Errore creazione task', 'error');
        return null;
    }
    
    // Notifica se assegnato ad altri
    if (taskData.assignedTo && taskData.assignedTo !== currentUser.id) {
        await createNotification(taskData.assignedTo, 'crm_reminder',
            'Nuovo task CRM: ' + taskData.title,
            '/crm/tasks'
        );
    }
    
    return data;
}

### 6. LOG COMUNICAZIONI

async function logCommunication(commData) {
    const { data, error } = await supabase
        .from('crm_communications')
        .insert({
            organization_id: state.organizationId,
            contact_id: commData.contactId,
            deal_id: commData.dealId || null,
            type: commData.type, // call_in, call_out, email_in, email_out, whatsapp_in, whatsapp_out, meeting, note
            subject: commData.subject || null,
            content: commData.content || '',
            duration_minutes: commData.duration || null,
            outcome: commData.outcome || null,
            user_id: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        showToast('Errore salvataggio', 'error');
        return null;
    }
    
    // Aggiorna last contact date
    await supabase
        .from('crm_contacts')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', commData.contactId);
    
    return data;
}

### 7. STATISTICHE CRM

async function getCRMStats() {
    const orgId = state.organizationId;
    
    // Contatti totali
    const { count: totalContacts } = await supabase
        .from('crm_contacts')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgId);
    
    // Trattative per stage
    const { data: deals } = await supabase
        .from('crm_deals')
        .select('stage, value')
        .eq('organization_id', orgId);
    
    const pipelineValue = deals?.filter(d => !['won', 'lost'].includes(d.stage))
        .reduce((sum, d) => sum + (d.value || 0), 0) || 0;
    
    const wonValue = deals?.filter(d => d.stage === 'won')
        .reduce((sum, d) => sum + (d.value || 0), 0) || 0;
    
    const wonCount = deals?.filter(d => d.stage === 'won').length || 0;
    const lostCount = deals?.filter(d => d.stage === 'lost').length || 0;
    const conversionRate = wonCount + lostCount > 0 
        ? Math.round(wonCount / (wonCount + lostCount) * 100) 
        : 0;
    
    // Task in scadenza oggi
    const today = new Date().toISOString().split('T')[0];
    const { count: tasksDueToday } = await supabase
        .from('crm_tasks')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgId)
        .eq('due_date', today)
        .eq('status', 'pending');
    
    return {
        totalContacts,
        pipelineValue,
        wonValue,
        conversionRate,
        tasksDueToday,
        wonCount,
        lostCount
    };
}

### 8. UI CRM

Crea nuova pagina/sezione CRM con:
- Lista contatti con ricerca e filtri
- Pipeline Kanban per deals
- Vista task/follow-up
- Form creazione contatto
- Form creazione trattativa
- Form creazione preventivo
- Dettaglio contatto con storico

## CRITERI DI SUCCESSO
- [ ] Check piano funziona
- [ ] CRUD contatti funziona
- [ ] Pipeline deals funziona
- [ ] Drag & drop deal stages funziona
- [ ] Preventivi generati correttamente
- [ ] Task CRM funzionano
- [ ] Log comunicazioni funziona
- [ ] Statistiche CRM corrette

<promise>FASE5_CRM_COMPLETE</promise>
" --max-iterations 60
```

---

## FASE 6: Admin Dashboard + Stripe

(Continua nel prossimo messaggio per limiti lunghezza...)

---

# PARTE 4: PRICING E PIANI

## Struttura Piani

```javascript
const PLANS = {
    free: {
        id: 'free',
        name: 'Free',
        price: 0,
        priceId: null,
        limits: {
            members: 1,
            teams: 0,
            projects: 3,
            contacts: 0, // No CRM
            storage_mb: 100
        },
        features: {
            crm: false,
            api: false,
            analytics: false,
            priority_support: false
        }
    },
    starter: {
        id: 'starter',
        name: 'Starter',
        price: 9,
        priceId: 'price_starter_xxx', // Da Stripe
        limits: {
            members: 5,
            teams: 1,
            projects: 10,
            contacts: 0,
            storage_mb: 500
        },
        features: {
            crm: false,
            api: false,
            analytics: false,
            priority_support: false
        }
    },
    pro: {
        id: 'pro',
        name: 'Pro',
        price: 19,
        priceId: 'price_pro_xxx',
        limits: {
            members: 15,
            teams: -1, // unlimited
            projects: -1,
            contacts: 500,
            storage_mb: 2000
        },
        features: {
            crm: true,
            api: false,
            analytics: true,
            priority_support: false
        }
    },
    business: {
        id: 'business',
        name: 'Business',
        price: 49,
        priceId: 'price_business_xxx',
        limits: {
            members: 50,
            teams: -1,
            projects: -1,
            contacts: -1,
            storage_mb: 10000
        },
        features: {
            crm: true,
            api: true,
            analytics: true,
            priority_support: true
        }
    }
};
```

---

# PARTE 5: CHECKLIST FINALE

## Prima del Lancio

### Tecnico
- [ ] Schema database eseguito
- [ ] Auth funzionante
- [ ] Tutti i moduli migrati
- [ ] Team/Progetti funzionanti
- [ ] CRM funzionante (piani pro)
- [ ] Realtime funzionante
- [ ] Admin dashboard funzionante
- [ ] Stripe funzionante
- [ ] Test su mobile
- [ ] Performance OK

### Legale
- [ ] Privacy Policy
- [ ] Terms of Service
- [ ] Cookie Policy

### Marketing
- [ ] Landing page
- [ ] Pricing page
- [ ] Screenshots/Demo

---

# FINE DOCUMENTO

Questo documento contiene tutto il necessario per trasformare SAVERS Pro in un SaaS commerciale.

Esegui le fasi in ordine con Ralph Loop.
Testa dopo ogni fase.
Buon lavoro! 🚀
