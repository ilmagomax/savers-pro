# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - Login Funzionante!

## ⚠️ AZIONE RICHIESTA - FIX RLS RECURSION

Prima di continuare, esegui questo SQL in **Supabase Dashboard > SQL Editor**:

```sql
-- FIX RECURSION - RLS POLICIES
DROP POLICY IF EXISTS "Users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same org" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Policy SEMPLICI (senza ricorsione)
CREATE POLICY "profiles_insert_own"
ON profiles FOR INSERT TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_select_own"
ON profiles FOR SELECT TO authenticated
USING (id = auth.uid());

CREATE POLICY "profiles_update_own"
ON profiles FOR UPDATE TO authenticated
USING (id = auth.uid());
```

Dopo l'esecuzione, fai logout e login di nuovo per testare.

---

## STATO PROGETTO

### ✅ Completato
- [x] Piano dettagliato approvato
- [x] Repository GitHub: https://github.com/ilmagomax/savers-pro
- [x] Deploy Vercel: https://savers-pro.vercel.app
- [x] CSS estratto in file separato
- [x] Supabase configurato e funzionante
- [x] Google OAuth configurato (Test mode, email aggiunto come tester)
- [x] **LOGIN FUNZIONANTE** - Auth Supabase con Google OAuth
- [x] Creazione automatica profilo utente

### ⚠️ Problema Attuale
- **RLS Infinite Recursion** - La policy "Users can view profiles" causa ricorsione infinita perché contiene una subquery sulla stessa tabella. Risolvi con lo script SQL sopra.

### 🔄 Da Fare (Prossime Fasi)
- [ ] FASE 2: Migrazione Dati Personali (Habits, Tasks, Transactions, ecc.)
- [ ] FASE 3: Team & Progetti
- [ ] FASE 4: Videocorsi (con link a GHL/Arcanis)
- [ ] FASE 5: Shop (con link a GHL/Arcanis)
- [ ] FASE 6: Push Notifications
- [ ] FASE 7: PWA Optimization
- [ ] FASE 8: Directus CMS Setup

---

## CONFIGURAZIONE

### Repository
- **GitHub**: https://github.com/ilmagomax/savers-pro
- **Vercel**: https://savers-pro.vercel.app
- **Branch**: main

### Supabase
- **URL**: https://lsrzcsymiuoutcmhcain.supabase.co
- **Anon Key**: sb_publishable_NFzbjbgsGgEn5enQg7M2VQ_XJoFb9RM
- **Site URL**: https://savers-pro.vercel.app
- **Redirect URLs**: https://savers-pro.vercel.app, https://savers-pro.vercel.app/**

### Google OAuth
- **Progetto**: SAVERS Pro
- **Status**: Testing mode (email aggiunto come tester)
- **Redirect URI**: https://lsrzcsymiuoutcmhcain.supabase.co/auth/v1/callback

---

## STRUTTURA FILE

```
/Users/ilmagicartista/Downloads/savers pro per la vendita/
├── index.html              # App principale (~26k righe)
├── css/styles.css          # CSS estratto (8910 righe)
├── manifest.json           # PWA config
├── sw.js                   # Service Worker
├── vercel.json             # Deploy config
├── .env.example            # Template variabili
├── .gitignore
├── CLAUDE_CONTEXT.md       # Questo file
├── SAVERS-PRO-COMPLETE-GUIDE.md  # Guida originale
└── sql/
    ├── 01-base-schema.sql  # Schema DB base (già eseguito)
    └── new-features.sql    # Schema per Videocorsi, Shop, Push
```

---

## CODICE CHIAVE

### Supabase Client (nel head)
```javascript
const SUPABASE_URL = 'https://lsrzcsymiuoutcmhcain.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_NFzbjbgsGgEn5enQg7M2VQ_XJoFb9RM';

function getSupabase() {
    if (supabaseClient) return supabaseClient;
    if (window.supabase && window.supabase.createClient) {
        supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        return supabaseClient;
    }
    return null;
}
```

### Funzioni Auth principali
- `loginWithGoogle()` - Login con Supabase OAuth
- `logout()` - Logout da Supabase
- `setupSupabaseAuth()` - Auth state listener
- `ensureUserProfile()` - Crea/carica profilo utente
- `checkExistingSession()` - Verifica sessione esistente

---

## PROSSIMI PASSI (FASE 2)

La FASE 2 riguarda la migrazione dei dati da localStorage a Supabase:

1. **Habits** - Tabella `habits` + `habit_logs`
2. **Tasks** - Tabella `tasks` (personali, non di progetto)
3. **Transactions** - Tabella `transactions`
4. **Books** - Tabella `books`
5. **Goals** - Tabella `goals`
6. **SAVERS Logs** - Tabella `savers_logs`
7. **Notes** - Tabella `notes`
8. **Pomodoro** - Tabella `pomodoro_sessions`

Pattern da usare:
- `load[Module]FromDB()` - Carica da Supabase
- `save[Module]ToDB(item)` - Salva su Supabase
- `update[Module]InDB(id, updates)` - Aggiorna
- `delete[Module]FromDB(id)` - Elimina
- `migrate[Module]FromLocalStorage()` - Migra dati esistenti

---

## NOTE PER NUOVA CHAT

Quando apri una nuova chat, usa questo prompt:

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md
e continua con la FASE 2: Migrazione Dati Personali.

Usa il metodo Ralph Loop:
- Prompt strutturati con obiettivi chiari
- Criteri di successo verificabili
- Promise tag per tracciare completamento
- Aggiorna CLAUDE_CONTEXT.md al termine di ogni fase
```

---

## PROMISE TAGS

- [x] FASE0_COMPLETE
- [x] FASE1_AUTH_COMPLETE
- [ ] FASE2_PERSONAL_DATA_COMPLETE
- [ ] FASE3_TEAM_COMPLETE
- [ ] FASE4_COURSES_COMPLETE
- [ ] FASE5_SHOP_COMPLETE
- [ ] FASE6_PUSH_COMPLETE
