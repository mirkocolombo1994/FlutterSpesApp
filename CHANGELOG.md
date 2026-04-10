# Registro delle Modifiche (Changelog)

### [0.4.0] - 2026-04-10

### ✨ Nuove Funzionalità
* **Motore Promozionale:** Gestione rigorosa dei vincoli per le offerte 1+1 e 3x2 (controllo incrociato di prezzo base, categoria, marca e nome radice).
* **Gestione Prodotti Freschi:** Inserita la possibilità di pesare manualmente i prodotti "freschi" (es. banco frigo/ortofrutta) e autocalcolo del Prezzo al Kg. Aggiornato lo Storico Prezzi (Schema v10) per tracciare queste metriche nel tempo.
* **Impostazioni Utente (Settings):** Inserita una dashboard configurabile con feedback aptico per lo scanner, blocco di sicurezza (richiesta quantità) prima di inserire nel carrello, filtri per nascondere alert visivi e opzione "Risparmio Dati" (evita di scaricare immagini API non necessarie da OpenFoodFacts).
* **Validazione Barcode Rigorosa:** Implementato Checksum (Algoritmo Modulo 10) per scartare in automatico QR Code errati, link web o codici non aderenti agli standard EAN/UPC.

### 🐛 Bug Fixes
* **Carrello e Fast Mode:** Risolti i check "Out of Scope" durante lo storno dei prodotti. La Fast Mode ora gestisce impeccabilmente il loop di fallback su nuovi record.
* **Compatibilità UI:** Evitato accumulo visivo dei Toast e migliorata scalabilità della griglia storica.
### [0.2.4](https://github.com/mirkocolombo1994/FlutterSpesApp/compare/v0.2.3...v0.2.4) (2026-03-24)


### 📚 Documentazione

* updated readme ([021c243](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/021c243f98118a27a6d42bbbddf3a8dfb57ba962))


### ✅ Test

* added tests ([93a2b08](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/93a2b08e402187378e5f95967475d37b6f8c0b58))


### ⚙️ Manutenzione

* added DevOps pipeline for testing and releases ([1f0646e](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/1f0646ec45e0a04b3e04a977b8086a25a7a1d413))


### 🐛 Bug Fixes

* fix errors on tests ([6d211df](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/6d211dffbe4de04f5717a9bb11847ad425e322a8))
* fix test node.js version ([7f14cb6](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/7f14cb6705aa4ca6b3091f5cd1e92bb550b6a9c8))
* fixed tests ([bcf5a0f](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/bcf5a0f6b4bee894d49ea9610cf98b3c396bec53))
* flutter version for tests ([01ab274](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/01ab274f8d3840d56fc1dcd883d6f7f30a59d726))
* stabilized product detail textfields to fix selection bug ([7c5cb75](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/7c5cb75253347604098d61663d44f3813b7b88fa))

### [0.2.3](https://github.com/mirkocolombo1994/FlutterSpesApp/compare/v0.2.2...v0.2.3) (2026-03-23)


### 💄 Stile e UI

* improved kart experience ([e701356](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/e70135669963c22ac8c88b4e58323e1906482bd2))


### ✨ Nuove Funzionalità

* added price history in kart ([8c5d36d](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/8c5d36d903dd4d3811c062ed89d217d92b7f09ff))
* added promo flag in superfast product insert ([151d181](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/151d18142b723e80c13446acf764826307b86f21))
* added promotions ([3267090](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/326709077fae67192081aed859cfb6c85d61dd38))
* added promotions labels and others ([afb829d](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/afb829d07584dd6057e8d3bebcdaed8a42218a43))
* message error in kart ([c168273](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/c1682737ba4f8417e25e4a4395a87fe8e0925ba8))


### ⚙️ Manutenzione

* updated gitignore ([ee494d6](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/ee494d688e09a4333cdacc9a4cc204ed14b92450))


### 📚 Documentazione

* added older commits in changelog.md ([e98159c](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/e98159c0c5297258fdde28079788047668fbad65))

### [0.2.2](https://github.com/mirkocolombo1994/FlutterSpesApp/compare/v0.2.1...v0.2.2) (2026-03-21)


### ✨ Nuove Funzionalità

* added order products and deleting products ([8feaf50](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/8feaf50))


### ⚙️ Manutenzione

* updated gitignore ([6ee89ac](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/6ee89ac))


### 💄 Stile e UI

* improved UI ([8e1f373](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/8e1f373))
* updated insering product infos ([2fad2c1](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/2fad2c1))

### [0.2.1](https://github.com/mirkocolombo1994/FlutterSpesApp/compare/v0.2.0...v0.2.1) (2026-03-20)


### ⚙️ Manutenzione

* added versioning ([81671bc](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/81671bc))
* added standard-version node and gitignore ([05e96f8](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/05e96f8))

### 0.2.0 (2026-03-20) - Alpha-2

### ✨ Nuove Funzionalità

* aggiunto versioning in homepage ([a960b65](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/a960b65))
* menu creato e opzioni barra inferiore semplificate ([bd2bb10](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/bd2bb10))
* aggiunta modifica campi e categorie ([62c201f](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/62c201f))
* gestione sconti iniziale ([2534dc7](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/2534dc7))

### 🐛 Bug Fixes

* fix cambio posizione supermercato nel carrello ([835f5c3](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/835f5c3))
* fix prodotti senza barcode, immagine o tipo ([c7ecf89](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/c7ecf89))

### ⚙️ Manutenzione

* centralizzate stringhe hardcoded ([70152a1](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/70152a1))
* aggiunti commenti al codice ([559763c](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/559763c))

### 0.1.0 (2026-03-19) - Initial Spesa Flow

### ✨ Nuove Funzionalità

* rilevamento automatico supermercato tramite GPS ([9f0d9fc](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/9f0d9fc))
* evidenza di nuovo supermercato aggiunto automaticamente ([495a858](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/495a858))
* implementazione carrello della spesa ([8c05904](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/8c05904))
* mappa per i punti vendita ([e8b49f3](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/e8b49f3))
* rilevamento supermercato da scansione prodotti freschi ([923078f](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/923078f))
* struttura base di SpesApp ([1167719](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/1167719))

### 🐛 Bug Fixes

* fix gestione prodotti già presenti nel carrello ([6c432a6](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/6c432a6))
* fix nome supermercato da mappa ([538011e](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/538011e))
* fix cancellazione notifiche snackbar ([35fbf7e](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/35fbf7e))

### ⚙️ Manutenzione

* bump version to alpha-2 ([fe7b5d8](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/fe7b5d8))
* pubblicazione app alpha iniziale ([fdb77de](https://github.com/mirkocolombo1994/FlutterSpesApp/commit/fdb77de))
