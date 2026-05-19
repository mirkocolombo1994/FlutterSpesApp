# Procedura Operativa Standard (SOP) - Rilascio SpesApp

Questa guida definisce il processo rigoroso per il rilascio di nuove versioni. Seguire questi passaggi garantisce stabilità, tracciabilità e integrità del database.

## Fase 1: Verifica Pre-Rilascio
Prima di iniziare la procedura git, è obbligatorio testare l'app in modalità reale per evitare "stuttering" da debug mode.
1. Collega un dispositivo fisico.
2. Esegui:
   ```bash
   flutter run --release
   ```
3. Verifica che i flussi principali (Scanner, Carrello, DB migrations) funzionino senza rallentamenti ("App isn't responding").

---

## Fase 2: Preparazione Metadati
1. **Aggiornamento Versione**: In `pubspec.yaml`, incrementa la `version`.
   - Modifica Minor (es. `0.3.x` -> `0.4.0`) per nuove feature consistenti.
   - Modifica Patch (es. `0.4.0` -> `0.4.1`) per soli bugfix.
   - Incrementa sempre il build number dopo il `+` (es. `+6` -> `+7`).
2. **Aggiornamento Changelog**: In `CHANGELOG.md`, aggiungi in testa la nuova versione con la data odierna.
   - Usa le icone: ✨ (Features), 🐛 (Bug Fixes), ⚙️ (Manutenzione).

---

## Fase 3: Consolidamento Sviluppo
Tutti i cambiamenti devono essere "congelati" sul branch di sviluppo.
```bash
git add .
git commit -m "chore: bump version to [VERSION] and update changelog"
git push origin develop
```

---

## Fase 4: Merge su Produzione (Main)
Il branch `main` deve sempre rappresentare l'ultimo stato stabile rilasciato.
1. Spostati su main: `git checkout main`
2. Aggiorna main: `git pull origin main` (Cruciale per evitare conflitti remoti)
3. Fondi lo sviluppo: `git merge develop`
4. Invia i cambiamenti: `git push origin main`

---

## Fase 5: Tagging Ufficiale
I tag permettono a GitHub Actions (e agli sviluppatori) di identificare i punti di rilascio.
1. Crea il tag annotato:
   ```bash
   git tag -a v0.4.0 -m "Release v0.4.0: [Titolo sintetico]"
   ```
2. Invia i tag al server:
   ```bash
   git push origin --tags
   ```

---

## Fase 6: Post-Rilascio
1. Torna subito su develop: `git checkout develop`
2. Verifica su GitHub che la release/tag sia visibile.

---

## Note Tecniche
- **Database**: Se hai modificato lo schema (DB Helper), assicurati che la versione nel codice sia stata incrementata PRIMA del merge.
- **Assets**: Se sono state aggiunte nuove immagini o font, verifica che siano listate in `pubspec.yaml`.
