# FASE 1: Shop & Videocorsi

Copia e incolla questo prompt in Claude Code dopo aver avviato `/ralph-loop`:

```
/ralph-loop "
## OBIETTIVO
Aggiungere sezione Shop e Videocorsi a SAVERS Pro con link esterni a GHL/Arcanis

## CONTESTO
- File esistente: index.html (PWA funzionante ~35k righe)
- Backend: Supabase Cloud (già configurato)
- I prodotti/corsi sono hostati su GHL/Arcanis
- L'app mostra preview e linka all'acquisto esterno
- Admin deve poter gestire contenuti visualmente

## STRUTTURA ESISTENTE
- Pagine usano classe 'page' con ID (es: tasksPage, financePage)
- Bottom nav con switchPage('nomepagina')
- Menu Altro (moreMenuModal) con griglia bottoni
- Modali con classe modal-overlay

## TASK

### 1. Schema Database Supabase
Crea file sql/shop-courses-schema.sql con:

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    short_description TEXT,
    image_url TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    external_url TEXT, -- Link GHL per acquisto
    category TEXT DEFAULT 'generale',
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    short_description TEXT,
    thumbnail_url TEXT,
    preview_video_url TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    external_url TEXT, -- Link GHL per acquisto
    duration_hours DECIMAL(5,2),
    lessons_count INTEGER DEFAULT 0,
    difficulty TEXT DEFAULT 'beginner',
    category TEXT DEFAULT 'generale',
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: tutti possono leggere, solo admin può scrivere
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY \"Products viewable by everyone\" ON products
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY \"Courses viewable by everyone\" ON courses
    FOR SELECT USING (is_active = TRUE);

### 2. Pagina Shop (shopPage)
In index.html, PRIMA di <!-- BOTTOM NAVIGATION -->, aggiungi:

<div class=\"page\" id=\"shopPage\">
    <div class=\"page-header\" style=\"margin-bottom:20px;\">
        <h1 style=\"font-size:1.5rem;font-weight:700;\">🛍️ Shop</h1>
        <p style=\"color:var(--text-secondary);font-size:0.9rem;\">I miei prodotti per te</p>
    </div>

    <div class=\"filter-pills\" style=\"display:flex;gap:8px;overflow-x:auto;margin-bottom:16px;\">
        <button class=\"pill active\" onclick=\"filterProducts('all')\">Tutti</button>
        <button class=\"pill\" onclick=\"filterProducts('digitale')\">Digitali</button>
        <button class=\"pill\" onclick=\"filterProducts('fisico')\">Fisici</button>
    </div>

    <div id=\"productsGrid\" style=\"display:grid;grid-template-columns:repeat(2,1fr);gap:12px;\">
        <!-- Prodotti caricati via JS -->
    </div>
</div>

### 3. Pagina Videocorsi (coursesPage)
Subito dopo shopPage aggiungi:

<div class=\"page\" id=\"coursesPage\">
    <div class=\"page-header\" style=\"margin-bottom:20px;\">
        <h1 style=\"font-size:1.5rem;font-weight:700;\">🎓 Videocorsi</h1>
        <p style=\"color:var(--text-secondary);font-size:0.9rem;\">Impara nuove skill</p>
    </div>

    <div class=\"filter-pills\" style=\"display:flex;gap:8px;overflow-x:auto;margin-bottom:16px;\">
        <button class=\"pill active\" onclick=\"filterCourses('all')\">Tutti</button>
        <button class=\"pill\" onclick=\"filterCourses('beginner')\">Principiante</button>
        <button class=\"pill\" onclick=\"filterCourses('intermediate')\">Intermedio</button>
        <button class=\"pill\" onclick=\"filterCourses('advanced')\">Avanzato</button>
    </div>

    <div id=\"coursesGrid\" style=\"display:flex;flex-direction:column;gap:16px;\">
        <!-- Corsi caricati via JS -->
    </div>
</div>

### 4. Menu Navigazione
Nel moreMenuModal (more-menu-grid), PRIMA di Analytics aggiungi:

<button class=\"more-menu-item\" onclick=\"closeModal('moreMenuModal'); switchPage('shop');\">
    <div class=\"more-menu-icon\">🛍️</div>
    <div class=\"more-menu-label\">Shop</div>
</button>
<button class=\"more-menu-item\" onclick=\"closeModal('moreMenuModal'); switchPage('courses');\">
    <div class=\"more-menu-icon\">🎓</div>
    <div class=\"more-menu-label\">Videocorsi</div>
</button>

### 5. Verifica
- Apri index.html nel browser
- Vai su Menu Altro
- Verifica che Shop e Videocorsi siano visibili
- Clicca e verifica che le pagine si aprano

## CRITERI DI SUCCESSO
- [ ] File sql/shop-courses-schema.sql creato
- [ ] shopPage aggiunto in index.html
- [ ] coursesPage aggiunto in index.html
- [ ] Voci Shop e Videocorsi nel menu Altro
- [ ] Pagine si aprono correttamente

<promise>FASE1_COMPLETE</promise>
" --max-iterations 20
```

---

## Dopo aver completato FASE 1, dimmi e ti do il prompt per FASE 2 (Admin Panel + Form)
