# Propozycja architektury sterowania głosowego (Wear OS + n8n + lokalne modele)

## 🎯 Cel i założenia
- **Cel**: Komendy głosowe z zegarka (Wear OS) przekształcane lokalnie w akcje w systemie (Notion, n8n, powiadomienia), z minimalnym opóźnieniem i pełną kontrolą prywatności.
- **Prywatność**: Audio, transkrypcja i inferencja LLM przetwarzane lokalnie (LAN). Brak wysyłki do chmury.
- **Niezawodność**: Proste scenariusze działają bez połączenia z Internetem; tolerancja na błędy (kolejki, retry).
- **Ewolucyjność**: Start od MVP (dodawanie/aktualizacja zadań), dalsza rozbudowa do zespołu agentów i orkiestracji.

## 🔎 Scenariusze użycia (MVP → Rozszerzenia)
- **MVP**:
  - „Dodaj zadanie ‘Pakowanie i przygotowanie do wyjazdu’ na 2025-08-29, priorytet wysoki.”
  - „Ustaw status ‘Zakończone’ dla zadania ‘Sprawdzenie stanu materiałów’.”
  - „Zapisz notatkę projektową: zamówienie paneli do piątku.”
- **Rozszerzenia**:
  - Materiały: „Dodaj materiał ‘Panele mech – 34m²’, status ‘Do zamówienia’.”
  - Ryzyka: „Zarejestruj ryzyko: opóźnienie dostaw, wpływ wysoki.”
  - Orkiestracja: „Zaplanuj transport roślin na piątek i przypisz ludzi.”

## 🏗️ Architektura logiczna
- **Wejście (Wear OS)**: Tasker (+ opcjonalnie AutoVoice)
  - Tryb A (lokalny, zalecany): Tasker nagrywa audio → wysyła `multipart/form-data` do n8n `/webhook/voice`.
  - Tryb B (szybki start): AutoVoice dostarcza rozpoznany tekst → Tasker wysyła `application/json` do n8n.
- **n8n (Ingress + Orkiestracja)**
  - Webhook `/webhook/voice` (token w URL + nagłówek `X-Auth-Token`).
  - Gałąź Audio: HTTP → lokalny serwis STT (Whisper) → tekst.
  - Normalizacja → NLU (reguły lub LLM/Ollama) → Intent + sloty.
  - Wykonanie akcji (Notion CRUD) + odpowiedź.
- **STT (Local Whisper)**
  - Kontener `faster-whisper`/`whisper-asr-webservice` w `docker-compose`.
  - Modele: `base`/`small` (PL/EN), opcjonalnie `medium` dla lepszej jakości.
- **LLM (Ollama)**
  - Modele: `llama3:8b` lub `mistral:7b`.
  - Ekstrakcja intencji i parametrów z tekstu; zwrot standaryzowanego JSON.
- **Bazy/Integracje**
  - Notion: bazy Tasks/Materials/Risks/Team (mapowanie zgodne z `config/notion/db_properties.md`).
  - Qdrant (FAZA 2): pamięć wektorowa (notatki, konteksty, historia dialogu).
- **Bezpieczeństwo**: Token w URL i nagłówku, whitelist IP, TLS w LAN (opcjonalnie), proste rate-limity.

## 🔌 Interfejsy i specyfikacje
### 1) Webhook n8n `/webhook/voice`
- Metoda: `POST`
- Tryby wejścia:
  - `multipart/form-data`: pole `audio` (WAV/OGG/MP3), nagłówek `X-Auth-Token: <sekret>`
  - `application/json`: `{ "text": "..." }`, nagłówek `X-Auth-Token`
- Parametry ochronne: `?token=<sekret>` w URL + nagłówek `X-Auth-Token` (oba wymagane)
- Odpowiedzi:
  - `200 OK`: `{ "status": "ok", "intent": "AddTask", "result": { ... } }`
  - `4xx`: walidacja, brak uprawnień, nieobsługiwany format
  - `5xx`: błąd wewnętrzny (STT/LLM/Notion)

Przykład (audio, Tasker):
```bash
curl -X POST "http://<LAN_IP>:5678/webhook/voice?token=SECRET" \
  -H "X-Auth-Token: SECRET" \
  -F "audio=@/path/to/voice.wav"
```

Przykład (tekst):
```bash
curl -X POST "http://<LAN_IP>:5678/webhook/voice?token=SECRET" \
  -H "X-Auth-Token: SECRET" -H "Content-Type: application/json" \
  -d '{"text": "Dodaj zadanie Pakowanie na 2025-08-29 priorytet wysoki"}'
```

### 2) Serwis STT (Whisper – lokalny)
- Endpoint (przykładowy): `POST /asr?language=pl` (body: plik audio)
- Odpowiedź: `{ "text": "..." }`
- Parametry: `language`, `task=transcribe`, `diarization=false`, `model=small|base|medium`
- Wydajność: CPU ok (base/small), GPU przy `medium`.

### 3) NLU/Ekstrakcja (LLM lub reguły)
- Wejście: surowy tekst po STT lub bezpośrednio z AutoVoice.
- Wynik (standaryzowany JSON):
```json
{
  "intent": "AddTask",                
  "entities": {
    "name": "Pakowanie i przygotowanie do wyjazdu",
    "dueDate": "2025-08-29",
    "priority": "High",
    "status": "Not Started"
  },
  "confidence": 0.78,
  "raw": "Dodaj zadanie ..."
}
```
- Intencje (MVP): `AddTask`, `UpdateTaskStatus`, `QuickNote`.
- Mapowanie priorytetów/statusów do słowników z `db_properties.md`.

### 4) Akcje w Notion (MVP)
- `AddTask` → Create Page w bazie `Tasks` z polami: `Name` (Title), `Status`, `Priority`, `Due Date`, `Description` (opcjonalnie).
- `UpdateTaskStatus` → Wyszukanie po tytule (lub ID jeśli wykryte) → Update `Status`.
- `QuickNote` → Strona/Notatka w dedykowanej bazie/sekcji (do decyzji) lub jako Task typu `Documentation`.

## ⚙️ Projekt przepływów (n8n)
1. Webhook `/voice`
2. IF: `content-type == multipart/*` → Gałąź Audio; ELSE → Gałąź Tekst
3. Audio → HTTP (STT) → tekst
4. Normalizacja: Code (trim, lower, format daty)
5. NLU:
   - A: Reguły (proste frazy-klucze)
   - B: LLM (Ollama) z promptem i schematem JSON (zalecane dla elastyczności)
6. IF: `intent == AddTask` → Notion Create
   - ELSE IF: `intent == UpdateTaskStatus` → Notion Update
   - ELSE IF: `intent == QuickNote` → Notion Create (notatka)
7. Zwróć `200 OK` z wynikiem i ewentualnym `pageId`
8. Log do pliku/Slack/Telegram (opcjonalnie)

## 🤖 Prompt i walidacja (LLM → JSON)
- System prompt (skrócony):
  - „Jesteś parserem komend. Zwracaj wyłącznie poprawny JSON z polami: intent, entities, confidence, raw. Daty w ISO 8601. Status/priorytet dopasuj do słowników.”
- Kilka przykładów (few-shot) z różnymi formami komend po polsku.
- Walidacja JSON w n8n: If/Code → jeśli niepoprawny, fallback do reguł lub prośba o doprecyzowanie.

## 🔐 Bezpieczeństwo
- Webhook tylko w **LAN**.
- Sekret w URL i nagłówku (oba wymagane).
- Whitelist IP urządzenia (router/n8n reverse proxy).
- Ograniczenia rozmiaru plików audio (np. ≤ 10 MB).
- Brak logowania surowego audio (tylko skróty metadanych).

## 📈 Obserwowalność i diagnostyka
- Logi n8n: sukces/porażka, czas transkrypcji, czas ekstrakcji intencji.
- Health-check STT i Ollama (rozszerzenie `scripts/health.sh`).
- Dashboard minimalny: liczba komend/dzień, dokładność intencji, średnie czasy.

## 🧪 Testy akceptacyjne (MVP)
- 5 komend na każdą intencję (różne formy językowe, daty, odmiany).
- SLA: transkrypcja < 3–5 s (base/small), ekstrakcja intencji < 1–2 s.
- Dokładność: ≥ 90% dla `AddTask` i `UpdateTaskStatus` na podstawowych formach.

## 🧩 Integracja z Tasker (Wear OS)
- Profil: Głos/gest → Task „Voice to n8n (local)”.
- Krok 1: **Record Audio** (limit 10–20 s, WAV/OGG). Zapis do `/sdcard/Tasker/voice/last.wav`.
- Krok 2: **HTTP Request** (POST, Multipart):
  - URL: `http://<LAN_IP>:5678/webhook/voice?token=SECRET`
  - Header: `X-Auth-Token: SECRET`
  - File param: `audio=@/sdcard/Tasker/voice/last.wav`
  - Timeout: 30–60 s, Retry: 1–2, On Error: pokaż notyfikację.
- Alternatywa (AutoVoice): zmienna z rozpoznanym tekstem → POST JSON `{ text: %avcomm }`.

## 🗺️ Roadmapa
- **FAZA 1 (MVP)**: Webhook `/voice`, STT lokalnie, intencje: `AddTask`, `UpdateTaskStatus`, `QuickNote`; Notion Create/Update; Tasker profil.
- **FAZA 2**: Orchestrator Agent (FastAPI + LangGraph/CrewAI), pamięć Qdrant, walidacja schematów Notion, retry/queue.
- **FAZA 3**: Zespół agentów (Planner/Notion/Logistics/Risk/Comms), powiadomienia, raporty dzienne.
- **FAZA 4**: TTS lokalnie (odpowiedzi głosowe), tryb offline (bufor komend), szersze intencje (materiały, ryzyka z parametrami).

## ⚠️ Ryzyka i mitigacje
- Niedokładność STT (szum, dialekt): dobór modelu (`small`/`medium`), krótkie komendy, cisza tła.
- Dwuznaczność komend: potwierdzenia/„reprompt” w odpowiedzi (tekst/push), słowniki dopasowań.
- Kolizje nazw zadań: identyfikacja po tytule + data + opcjonalnie ID.
- Wydajność CPU: zacząć od `base/small`; rozważyć GPU jeśli dostępne.
- Utrzymanie prywatności: brak logowania audio, tylko metadane; LAN-only.

## 💰 Szacunkowe koszty i zasoby
- Brak kosztów chmurowych (lokalne modele).
- Wymagania sprzętowe: CPU 4C/8G RAM komfortowo dla `small`; dla `medium` przyda się GPU lub cierpliwość.
- Czas wdrożenia FAZA 1: 0.5–1 dzień (wraz z konfiguracją Tasker).

## 📎 Załączniki (przykłady)
- Przykładowy wynik STT:
```json
{ "text": "dodaj zadanie pakowanie na dwudziestego dziewiątego sierpnia priorytet wysoki" }
```
- Przykładowy JSON po NLU:
```json
{
  "intent": "AddTask",
  "entities": {
    "name": "Pakowanie i przygotowanie do wyjazdu",
    "dueDate": "2025-08-29",
    "priority": "High",
    "status": "Not Started"
  },
  "confidence": 0.82,
  "raw": "Dodaj zadanie ..."
}
```
- Przykładowa odpowiedź n8n:
```json
{ "status": "ok", "intent": "AddTask", "result": { "pageId": "...", "name": "Pakowanie..." } }
```
