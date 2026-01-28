-- ============================================
-- SAVERS PRO - NUOVE FEATURES
-- Videocorsi, Shop, Push Notifications
-- Esegui in Supabase Dashboard > SQL Editor
-- ============================================

-- ============================================
-- 1. VIDEOCORSI / COURSES
-- ============================================
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,

    -- Info base
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,

    -- Video
    video_url TEXT,                    -- Link a video esterno (YouTube/Vimeo/GHL)
    video_provider TEXT DEFAULT 'youtube' CHECK (video_provider IN ('youtube', 'vimeo', 'ghl', 'external')),
    duration_minutes INTEGER,

    -- Acquisto
    external_purchase_url TEXT,        -- Link per acquisto su GHL/Arcanis
    price DECIMAL(10,2) DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    is_free BOOLEAN DEFAULT FALSE,

    -- Categorizzazione
    category TEXT,
    tags TEXT[],

    -- Collegamento a Skill
    skill_id UUID REFERENCES skills(id) ON DELETE SET NULL,
    xp_reward INTEGER DEFAULT 0,       -- XP guadagnati completando il corso

    -- Ordinamento e visibilità
    position INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,

    -- Metadata
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tracciamento progressi utente sui corsi
CREATE TABLE IF NOT EXISTS user_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,

    -- Stato
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    progress_percent INTEGER DEFAULT 0,

    -- Acquisto
    purchased BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMPTZ,
    purchase_reference TEXT,           -- ID transazione GHL/Stripe

    -- Completamento
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    xp_earned INTEGER DEFAULT 0,

    -- Watch time
    last_position_seconds INTEGER DEFAULT 0,
    total_watch_seconds INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, course_id)
);

-- ============================================
-- 2. PRODOTTI SHOP
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,

    -- Info base
    title TEXT NOT NULL,
    description TEXT,
    short_description TEXT,

    -- Immagini
    image_url TEXT,
    gallery_urls TEXT[],

    -- Acquisto
    external_purchase_url TEXT,        -- Link per acquisto su GHL/Arcanis
    price DECIMAL(10,2) NOT NULL,
    compare_at_price DECIMAL(10,2),    -- Prezzo barrato (scontato da)
    currency TEXT DEFAULT 'EUR',

    -- Tipo prodotto
    product_type TEXT DEFAULT 'physical' CHECK (product_type IN ('physical', 'digital', 'service')),

    -- Categorizzazione
    category TEXT,
    tags TEXT[],

    -- Stock (solo per prodotti fisici)
    stock_quantity INTEGER,
    track_stock BOOLEAN DEFAULT FALSE,

    -- Ordinamento e visibilità
    position INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,

    -- Metadata
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. PUSH NOTIFICATIONS
-- ============================================

-- Sottoscrizioni push degli utenti
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Web Push subscription data
    endpoint TEXT NOT NULL,
    keys JSONB NOT NULL,               -- { p256dh, auth }

    -- Device info
    device_type TEXT DEFAULT 'web' CHECK (device_type IN ('web', 'ios', 'android')),
    device_name TEXT,
    user_agent TEXT,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, endpoint)
);

-- Notifiche push inviate
CREATE TABLE IF NOT EXISTS push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,

    -- Contenuto
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    icon_url TEXT,
    image_url TEXT,

    -- Azione click
    action_url TEXT,
    action_type TEXT DEFAULT 'open_app' CHECK (action_type IN ('open_app', 'open_url', 'open_course', 'open_product')),
    action_id UUID,                    -- ID del corso/prodotto se applicabile

    -- Targeting
    target_type TEXT DEFAULT 'all' CHECK (target_type IN ('all', 'segment', 'users')),
    target_users UUID[],               -- Se target_type = 'users'
    target_segment TEXT,               -- Se target_type = 'segment' (es: 'pro_users', 'inactive')

    -- Scheduling
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,

    -- Stats
    sent_count INTEGER DEFAULT 0,
    delivered_count INTEGER DEFAULT 0,
    clicked_count INTEGER DEFAULT 0,

    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
    error_message TEXT,

    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Log delle notifiche inviate per utente
CREATE TABLE IF NOT EXISTS push_notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES push_notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES push_subscriptions(id) ON DELETE SET NULL,

    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'clicked', 'failed')),
    error_message TEXT,

    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Courses
CREATE INDEX IF NOT EXISTS idx_courses_org ON courses(organization_id);
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category);
CREATE INDEX IF NOT EXISTS idx_user_courses_user ON user_courses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_courses_course ON user_courses(course_id);

-- Products
CREATE INDEX IF NOT EXISTS idx_products_org ON products(organization_id);
CREATE INDEX IF NOT EXISTS idx_products_published ON products(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- Push
CREATE INDEX IF NOT EXISTS idx_push_subs_user ON push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_subs_active ON push_subscriptions(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_push_notif_org ON push_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_push_notif_status ON push_notifications(status);
CREATE INDEX IF NOT EXISTS idx_push_logs_notif ON push_notification_logs(notification_id);
CREATE INDEX IF NOT EXISTS idx_push_logs_user ON push_notification_logs(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_logs ENABLE ROW LEVEL SECURITY;

-- Courses: tutti possono vedere i pubblicati, admin può gestire
CREATE POLICY "Anyone can view published courses" ON courses
    FOR SELECT USING (is_published = TRUE OR organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Admins can manage courses" ON courses
    FOR ALL USING (is_org_admin() OR is_super_admin());

-- User Courses: utenti gestiscono i propri
CREATE POLICY "Users manage own course progress" ON user_courses
    FOR ALL USING (user_id = auth.uid());

-- Products: tutti possono vedere i pubblicati, admin può gestire
CREATE POLICY "Anyone can view published products" ON products
    FOR SELECT USING (is_published = TRUE OR organization_id = get_user_org_id() OR is_super_admin());

CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (is_org_admin() OR is_super_admin());

-- Push Subscriptions: utenti gestiscono le proprie
CREATE POLICY "Users manage own push subscriptions" ON push_subscriptions
    FOR ALL USING (user_id = auth.uid());

-- Push Notifications: admin può gestire
CREATE POLICY "Admins can manage push notifications" ON push_notifications
    FOR ALL USING (is_org_admin() OR is_super_admin());

CREATE POLICY "Users can view own notification logs" ON push_notification_logs
    FOR SELECT USING (user_id = auth.uid() OR is_super_admin());

-- ============================================
-- TRIGGERS
-- ============================================

CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_courses_updated_at
    BEFORE UPDATE ON user_courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- SAMPLE DATA (opzionale - rimuovi in produzione)
-- ============================================

-- Categorie corsi di esempio
-- INSERT INTO courses (organization_id, title, description, is_free, is_published, category) VALUES
-- (NULL, 'Corso Base Animazione', 'Impara le basi dell''animazione per feste', TRUE, TRUE, 'Animazione'),
-- (NULL, 'Balloon Art Avanzato', 'Tecniche avanzate di scultura palloncini', FALSE, TRUE, 'Tecnica');

-- ============================================
-- DONE!
-- ============================================
