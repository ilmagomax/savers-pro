-- ============================================
-- SAVERS PRO - SHOP & VIDEOCORSI
-- Schema per Supabase
-- ============================================

-- ============================================
-- 1. PRODOTTI (SHOP)
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Info prodotto
    title TEXT NOT NULL,
    slug TEXT UNIQUE,
    description TEXT,
    short_description TEXT,

    -- Immagini
    image_url TEXT,
    gallery JSONB DEFAULT '[]', -- Array di URL immagini

    -- Prezzi
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',

    -- Link esterno GHL/Arcanis
    external_url TEXT, -- Link per acquisto su GHL

    -- Categorizzazione
    category TEXT DEFAULT 'generale',
    tags JSONB DEFAULT '[]',

    -- Stato
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    stock_quantity INTEGER DEFAULT -1, -- -1 = illimitato

    -- SEO
    meta_title TEXT,
    meta_description TEXT,

    -- Ordinamento
    sort_order INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

-- ============================================
-- 2. VIDEOCORSI
-- ============================================
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Info corso
    title TEXT NOT NULL,
    slug TEXT UNIQUE,
    description TEXT,
    short_description TEXT,

    -- Immagini/Video
    thumbnail_url TEXT,
    preview_video_url TEXT, -- Video anteprima gratuito

    -- Prezzi
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',

    -- Link esterno GHL/Arcanis
    external_url TEXT, -- Link per acquisto su GHL

    -- Dettagli corso
    duration_hours DECIMAL(5,2), -- Durata totale in ore
    lessons_count INTEGER DEFAULT 0,
    difficulty TEXT DEFAULT 'beginner' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),

    -- Categorizzazione
    category TEXT DEFAULT 'generale',
    tags JSONB DEFAULT '[]',

    -- Stato
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_coming_soon BOOLEAN DEFAULT FALSE,

    -- SEO
    meta_title TEXT,
    meta_description TEXT,

    -- Ordinamento
    sort_order INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

-- ============================================
-- 3. LEZIONI DEI CORSI
-- ============================================
CREATE TABLE course_lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,

    -- Info lezione
    title TEXT NOT NULL,
    description TEXT,

    -- Contenuto
    video_url TEXT, -- URL video (YouTube, Vimeo, etc)
    duration_minutes INTEGER DEFAULT 0,

    -- Ordinamento
    module_number INTEGER DEFAULT 1,
    lesson_number INTEGER DEFAULT 1,

    -- Stato
    is_free BOOLEAN DEFAULT FALSE, -- Lezione gratuita di preview
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. NOTIFICHE PUSH
-- ============================================
CREATE TABLE push_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

    -- FCM Token
    fcm_token TEXT NOT NULL,
    device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
    device_name TEXT,

    -- Stato
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, fcm_token)
);

CREATE TABLE push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Contenuto
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    action_url TEXT,

    -- Target
    target_type TEXT DEFAULT 'all' CHECK (target_type IN ('all', 'segment', 'user')),
    target_users JSONB DEFAULT '[]', -- Array di user_id se target specifico

    -- Stato
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sent', 'cancelled')),
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,

    -- Stats
    sent_count INTEGER DEFAULT 0,
    opened_count INTEGER DEFAULT 0,

    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. INDICI
-- ============================================
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_featured ON products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_products_category ON products(category);

CREATE INDEX idx_courses_active ON courses(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_courses_featured ON courses(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_courses_category ON courses(category);

CREATE INDEX idx_lessons_course ON course_lessons(course_id);
CREATE INDEX idx_push_subs_user ON push_subscriptions(user_id);

-- ============================================
-- 6. TRIGGER PER updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER lessons_updated_at
    BEFORE UPDATE ON course_lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 7. RLS (Row Level Security)
-- ============================================
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- Prodotti: tutti possono leggere quelli attivi
CREATE POLICY "Products viewable by everyone" ON products
    FOR SELECT USING (is_active = TRUE);

-- Corsi: tutti possono leggere quelli attivi
CREATE POLICY "Courses viewable by everyone" ON courses
    FOR SELECT USING (is_active = TRUE);

-- Lezioni: tutti possono leggere quelle attive
CREATE POLICY "Lessons viewable by everyone" ON course_lessons
    FOR SELECT USING (is_active = TRUE);

-- Push subscriptions: solo il proprio utente
CREATE POLICY "Users can manage own subscriptions" ON push_subscriptions
    FOR ALL USING (auth.uid() = user_id);

-- Admin può fare tutto (per super_admin)
CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (is_super_admin = TRUE OR org_role = 'owner')
        )
    );

CREATE POLICY "Admins can manage courses" ON courses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (is_super_admin = TRUE OR org_role = 'owner')
        )
    );

CREATE POLICY "Admins can manage lessons" ON course_lessons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (is_super_admin = TRUE OR org_role = 'owner')
        )
    );

CREATE POLICY "Admins can manage notifications" ON push_notifications
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (is_super_admin = TRUE OR org_role = 'owner')
        )
    );

-- ============================================
-- FATTO! Schema Shop & Videocorsi pronto
-- ============================================
