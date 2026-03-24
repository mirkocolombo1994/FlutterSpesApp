# SpesApp Testing 🧪

In questa cartella troverai la suite completa di test per SpesApp. I test sono organizzati in diversi livelli per garantire massima affidabilità e facilità di manutenzione.

## 📂 Struttura della Cartella `test/`

*   **`mocks/`**: Contiene classi e widget "finti" per isolare i test dalle dipendenze esterne (es. Database, GPS).
*   **`models/`**: Unit test per i modelli di dati (`Product`, `Store`, `PriceHistory`).
*   **`providers/`**: Test per i Notifier di Riverpod (`CartNotifier`, `ProductNotifier`). Questi test verificano che la logica di business e la gestione dello stato siano corrette.
*   **`widgets/`**: Widget test per verificare il corretto rendering dei componenti UI.

---

## 🚀 Come eseguire i test

### 1. Eseguire tutti i test
Per far girare l'intera suite di test, usa il comando standard di Flutter:

```bash
flutter test
```

### 2. Eseguire un test specifico
Se vuoi testare solo un file specifico:

```bash
flutter test test/providers/cart_provider_test.dart
```

---

## 🛠️ Tecnologie Utilizzate

*   **`mocktail`**: Per creare mock degli oggetti in modo leggibile e senza generazione di codice.
*   **`ProviderContainer`**: Utilizzato per testare gli stati di Riverpod in modo nativo e robusto.
*   **`sqflite_common_ffi`**: Per permettere l'esecuzione dei test che coinvolgono il DB direttamente sulla tua macchina Windows.

---

## 💡 Best Practices

*   **Indipendenza**: Ogni test deve essere atomico e non dipendere dall'esito di altri test.
*   **Nomenclatura**: Usa nomi descrittivi per i gruppi e i test (es. `Should add item to cart correctly`).
*   **Mocking**: Se un test coinvolge chiamate al DB o servizi di sistema, usa sempre un Mock per evitare effetti collaterali.
