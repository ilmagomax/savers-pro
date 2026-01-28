# SAVERS PRO - Context File per Claude Code
> Aggiornato: 2026-01-28 - Sistema Compensi Agenzia per Animatori

## STATO PROGETTO ATTUALE

### Sistema Compensi Agenzia (IN LAVORAZIONE)

Sistema di gestione compensi per agenzie di animazione con flusso bidirezionale animatore-proprietario.

#### Struttura Dati Commento Finanziario (Income)
```javascript
{
    id: 'comment_xxx',
    type: 'income',
    incomeTotal: 100,           // Ritiro Saldo totale
    animatorProfit: 50,         // Guadagno animatore (Tuo Guadagno)
    animatorExpenses: 20,       // Spese sostenute dall'animatore
    agencyFee: 30,              // Compensi Agenzia (da consegnare)
    agencyFeeDelivered: false,  // Segnato come consegnato
    agencyFeeConfirmed: false,  // Confermato dal proprietario
    agencyFeeModifiedByOwner: false,  // Owner ha modificato l'importo
    agencyFeeAnimatorAccepted: false, // Animatore ha accettato modifica
    agencyFeeLog: []            // Log attività con timestamp
}
```

#### Flusso Consegna Compensi
1. **PENDING**: Animatore registra incasso, compensi da consegnare
2. **PENDING_OWNER_CONFIRMATION**: Animatore clicca "Segna come Consegnato"
3. Owner può:
   - **Confermare** → stato CONFIRMED
   - **Modificare importo** → stato PENDING_ANIMATOR_CONFIRMATION
4. Se modificato, Animatore può:
   - **Accettare** → torna a PENDING_OWNER_CONFIRMATION
   - **Rifiutare** → torna a PENDING (deve ri-consegnare)

#### Vista Finanziaria Differenziata

**Vista Agenzia (Owner/Admin):**
- Ritiro Saldo: €100
- Spese Totali: €70 (€50 guadagno anim. + €20 spese)
- Profitto Agenzia: €30

**Vista Animatore (4 colonne):**
- Ritiro Saldo: €100
- Spese: €20
- Guadagno: €50
- Compensi Ag.: €30

#### Funzioni Chiave (index.html)
- `renderAgencyFeeWallet()` - Wallet Compensi mensile (~riga 17653)
- `openAgencyFeeDetail()` - Modal dettaglio compensi
- `markAgencyFeesAsDelivered()` - Animatore segna consegnato
- `confirmAgencyFeesReceived()` - Owner conferma ricezione
- `openEditAgencyFee()` / `saveAgencyFeeModification()` - Owner modifica
- `acceptOwnerModification()` / `rejectOwnerModification()` - Animatore accetta/rifiuta
- `getAgencyFeesForMonth(yearMonth)` - Calcola compensi per mese (~riga 17570)
- `renderEventsDashboard()` - Dashboard Feste & Eventi (~riga 18737)
- `renderEventFinanceSummaryFromComments()` - Riepilogo evento (~riga 17314)
- `showEventFinanceDetail()` - Dettaglio evento dalla dashboard (~riga 19215)
- `canSeeFinancialComment()` - Controllo visibilità commenti (~riga 30842)

#### Permessi Modifica/Elimina Commenti
- **Owner/Admin**: Può SEMPRE modificare/eliminare qualsiasi commento
- **Animatore**: Può modificare/eliminare SOLO i propri commenti entro 5 minuti

### Bug Risolti Oggi (2026-01-28)

1. **Calcoli finanziari errati** - Usava `animatorEarning` invece di `animatorProfit`
2. **guadagnoAnimatore mancante** - Variabile non dichiarata in showEventFinanceDetail
3. **Fallback calcolo** - Aggiunto: se `animatorProfit` è null, calcola `incomeTotal - agencyFee - animatorExpenses`
4. **Owner vede tutti i commenti** - Aggiunto check `isOwnerOrAdmin` in `canSeeFinancialComment()`
5. **Owner può sempre editare** - Rimosso limite 5 minuti per owner/admin

### Da Completare

- [ ] Verificare che owner veda commenti da calendari diversi (stesso evento)
- [ ] Testare flusso completo consegna compensi
- [ ] Testare modifica importo da owner e accetta/rifiuta da animatore
- [ ] Click su evento dalla dashboard Feste & Eventi

---

## CONFIGURAZIONE

### Repository
- **GitHub**: https://github.com/ilmagomax/savers-pro
- **Vercel**: https://savers-pro.vercel.app
- **Branch**: main

### Supabase
- **URL**: https://lsrzcsymiuoutcmhcain.supabase.co
- **Anon Key**: sb_publishable_NFzbjbgsGgEn5enQg7M2VQ_XJoFb9RM

---

## FASI COMPLETATE

- [x] FASE 0: Setup Progetto
- [x] FASE 1: Auth Migration a Supabase
- [x] FASE 2: Migrazione Dati Personali (Habits, Tasks, Transactions, Books, Goals, Notes, Money Goals)
- [x] FASE 2+: Wallets, Commenti Finanziari Eventi, OCR Scontrini

## FASI FUTURE

- [ ] FASE 3: Team & Progetti
- [ ] FASE 4: Videocorsi
- [ ] FASE 5: Shop
- [ ] FASE 6: Push Notifications

---

## NOTE PER NUOVA CHAT

```
Leggi /Users/ilmagicartista/Downloads/savers pro per la vendita/CLAUDE_CONTEXT.md

CONTESTO: Sistema Compensi Agenzia per animatori.
- Flusso bidirezionale: Animatore consegna → Owner conferma/modifica → Animatore accetta/rifiuta
- Vista differenziata: Owner vede profitto agenzia, Animatore vede suo guadagno
- Campi chiave: incomeTotal, animatorProfit, animatorExpenses, agencyFee

DA VERIFICARE:
1. Owner vede TUTTI i commenti finanziari (anche da calendari diversi)
2. Calcoli corretti: Guadagno=animatorProfit, Spese=animatorExpenses
3. Click evento dalla dashboard Feste & Eventi funziona
4. Flusso consegna compensi completo

FILE PRINCIPALE: /Users/ilmagicartista/Downloads/savers pro per la vendita/index.html
```
