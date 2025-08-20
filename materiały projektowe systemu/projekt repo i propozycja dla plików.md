Uwielbiam to podejście: najpierw projekt, potem „jeden przycisk” do postawienia całości. Poniżej dostajesz komplet: **architekturę**, **strukturę katalogów**, oraz **gotowy installer** (bash), który:

* sprawdza zależności (Docker, Compose, cURL, dostępne porty),
* przygotowuje `.env` (z podpowiedziami),
* pobiera obrazy, uruchamia stack,
* ściąga model do Ollamy,
* robi testy zdrowia,
* wypisuje instrukcje do skonfigurowania Cursor → MCP i pierwsze komendy.

Jeśli chcesz, możesz od razu wkleić pliki 1:1 i odpalić.

---

# 🏗️ Architektura (co, gdzie i po co)

```
┌─────────────────────────────────────────────────────────┐
│                         Cursor                          │
│              (IDE + obsługa MCP + czat)                │
└───────────────▲───────────────────────────────▲────────┘
                │                               │
        MCP (HTTP 7410)                   Ollama (11434)
                │                               │
┌───────────────┴───────────────┐       ┌───────┴────────┐
│        MCP-Notion Server      │       │   Ollama LLM   │
│ (mostek Cursor ⇄ Notion API)  │       │ (lokalny model)│
└───────────────▲───────────────┘       └───────▲────────┘
                │                               │
          Notion API                      n8n (5678)
                │                               │
                └───────────┬───────────────────┘
                            │
                      Automatyzacje
              (np. Notion → Slack/Email)
```

* **MCP-Notion (self‑hosted)** – serwer MCP mapujący polecenia na Notion API (CRUD stron/baz/relacji).
* **Ollama** – lokalny model (np. `llama3.1:8b`) do pracy w Cursor bez chmury.
* **n8n** – automatyzacje (webhooki, crony; np. eskalacje zadań zablokowanych).
* **Cursor** – Twoje IDE, zintegrowane z MCP i modelem.

---

# 📁 Struktura repo

```
bws-stack/
├─ docker-compose.yml
├─ .env.example
├─ Makefile
├─ README.md
├─ config/
│  ├─ cursor.mcp.json          # do wklejenia w Cursor → Settings → MCP
│  ├─ n8n/
│  │  ├─ flows/
│  │  │  ├─ escalation.json    # przykładowy flow: eskalacja zablokowanych
│  │  │  └─ materials_unlock.json
│  └─ notion/
│     └─ db_properties.md      # mapowanie pól w bazach Notion (Zadania, Materiały, Ryzyka, Zespół)
└─ scripts/
   ├─ install.sh               # ⬅️ główny installer (uruchomisz 1 poleceniem)
   ├─ checks.sh                # sprawdzenia zależności/portów
   ├─ pull_models.sh           # pobranie modeli Ollama
   └─ health.sh                # testy zdrowia usług
```

---

# 🧰 1) `docker-compose.yml`

> Używam przykładowego obrazu MCP (nazwij go jak chcesz). Jeśli masz swój – podmień `image:`.

```yaml
version: "3.8"

services:
  notion-mcp:
    image: ghcr.io/example/notion-mcp-server:latest
    environment:
      NOTION_TOKEN: ${NOTION_TOKEN}
      NOTION_BASE_PAGE_ID: ${NOTION_BASE_PAGE_ID}
      NOTION_VERSION: "2022-06-28"
    ports:
      - "7410:7410"
    restart: unless-stopped

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped

  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_SECURE_COOKIE=false
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

volumes:
  ollama_data:
  n8n_data:
```

---

# 🔐 2) `.env.example`

```env
# ===== Notion Integration =====
# Utwórz integrację na developers.notion.com, skopiuj token.
NOTION_TOKEN=secret_xxxxxxxxxxxxxxxxxxxxxxxxx

# Opcjonalnie: bazowa strona/baza (ułatwia operacje)
NOTION_BASE_PAGE_ID=xxxxxxxxxxxxxxxxxxxxxxxx

# ===== Ports (zmień, jeśli zajęte) =====
PORT_MCP=7410
PORT_OLLAMA=11434
PORT_N8N=5678
```

Skopiuj jako `.env` i uzupełnij.

---

# 🏗️ 3) `scripts/checks.sh`

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Sprawdzam zależności..."
command -v docker >/dev/null 2>&1 || { echo "❌ Brak Docker. Zainstaluj i uruchom (Docker Desktop / daemon)."; exit 1; }
command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { echo "❌ Brak Docker Compose."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "❌ Brak curl."; exit 1; }

# Ports
PORT_MCP=${PORT_MCP:-7410}
PORT_OLLAMA=${PORT_OLLAMA:-11434}
PORT_N8N=${PORT_N8N:-5678}

for p in $PORT_MCP $PORT_OLLAMA $PORT_N8N; do
  if lsof -Pi :$p -sTCP:LISTEN -t >/dev/null ; then
    echo "❌ Port $p jest zajęty. Zamknij usługę albo zmień port w .env."
    exit 1
  fi
done

echo "✅ Zależności OK."
```

---

# 🎛️ 4) `scripts/pull_models.sh`

```bash
#!/usr/bin/env bash
set -e
echo "🤖 Pobieram model do Ollama..."
curl -s http://localhost:11434/api/tags >/dev/null || { echo "⏳ Czekam na Ollama..."; sleep 3; }
# pobierz sensowny model startowy (możesz zmienić na większy)
docker exec $(docker ps --filter "ancestor=ollama/ollama:latest" -q) ollama pull llama3.1:8b
echo "✅ Model pobrany: llama3.1:8b"
```

---

# 🩺 5) `scripts/health.sh`

```bash
#!/usr/bin/env bash
set -e

echo "🩺 Sprawdzam MCP..."
curl -sS http://localhost:${PORT_MCP:-7410}/health || echo "ℹ️ MCP może nie mieć /health – ważne, by odpowiadał na żądania."

echo "🩺 Sprawdzam Ollama..."
curl -sS http://localhost:${PORT_OLLAMA:-11434}/api/tags | grep -q '"models"' && echo "✅ Ollama OK" || echo "❌ Problem z Ollama"

echo "🩺 Sprawdzam n8n..."
curl -sS http://localhost:${PORT_N8N:-5678} >/dev/null && echo "✅ n8n OK" || echo "❌ Problem z n8n"
```

---

# 🚀 6) `scripts/install.sh` (główny installer)

```bash
#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🧩 Installer BWS-STACK"
echo "1) Sprawdzam zależności..."
bash scripts/checks.sh

echo "2) Tworzę plik .env jeśli brak..."
if [ ! -f .env ]; then
  cp .env.example .env
  echo "⚠️  Uzupełnij .env (NOTION_TOKEN, NOTION_BASE_PAGE_ID) i uruchom ponownie:"
  echo "    nano .env"
  exit 0
fi

echo "3) Uruchamiam kontenery..."
docker compose up -d

echo "4) Czekam, aż Ollama wstanie..."
for i in {1..20}; do
  if curl -s http://localhost:${PORT_OLLAMA:-11434}/api/tags >/dev/null; then
    break
  fi
  sleep 1
done

echo "5) Pobieram model do Ollama..."
bash scripts/pull_models.sh || true

echo "6) Testy zdrowia..."
bash scripts/health.sh || true

cat <<EOF

🎉 GOTOWE!

🔗 n8n:      http://localhost:${PORT_N8N:-5678}
🤖 Ollama:   http://localhost:${PORT_OLLAMA:-11434}
🧠 MCP:      http://localhost:${PORT_MCP:-7410} (rejestruj w Cursor)

➡️ Następne kroki (Cursor):
1) Otwórz Cursor → Settings → MCP → Add:
{
  "name": "notion-mcp",
  "transport": "http",
  "url": "http://localhost:${PORT_MCP:-7410}"
}
2) Settings → Models → dodaj Ollama:
   Endpoint: http://localhost:${PORT_OLLAMA:-11434}
   Model:    llama3.1:8b

✅ Pierwszy test w Cursor:
- „Użyj MCP, wyszukaj w bazie 'Zadania' po Status=Zablokowane i pokaż Nazwa + Termin”
- „Utwórz zadanie ‘Pakowanie i przygotowanie do wyjazdu’ na 2025-08-29 i zależne od ‘Sprawdzenie stanu zamówionych materiałów’”

ℹ️ Jeśli n8n ma działać za VPN/proxy – dodaj reverse proxy (np. nginx/caddy) i HTTPS.

EOF
```

Nadaj prawa:

```bash
chmod +x scripts/*.sh
```

---

# 🧷 7) `Makefile` (opcjonalnie, wygoda)

```makefile
.PHONY: up down logs health install reset

install:
	./scripts/install.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

health:
	./scripts/health.sh

reset:
	docker compose down -v
	rm -f .env
```

---

# 🧩 8) Konfiguracja MCP dla Cursor – `config/cursor.mcp.json`

```json
{
  "name": "notion-mcp",
  "transport": "http",
  "url": "http://localhost:7410"
}
```

---

# 📒 9) Mapowanie pól Notion – `config/notion/db_properties.md`

Skopiuj do Notion, żeby trzymać standard:

```markdown
# Bazy i właściwości (ustal standard nazw)

## Zadania
- Nazwa Zadania (Title)
- Status (Select: Do zrobienia, W toku, Zablokowane, Zakończone)
- Osoba Odpowiedzialna (Relation → Zespół)
- Termin (Date)
- Zależy od (Relation → Zadania)
- Blokuje (Relation → Zadania)
- Powiązane Ryzyka (Relation → Ryzyka)
- Powiązane Materiały (Relation → Materiały)
- Done? (Formula: prop("Status") = "Zakończone")
- Zależności: % zakończonych (Rollup: Zależy od → Done? → Percent checked)
- Auto: Zablokowane (Formula: if(empty(prop("Zależy od")), false, prop("Zależności: % zakończonych") < 1))
- Opóźnione? (Formula: and(prop("Status") != "Zakończone", now() > prop("Termin")))

## Ryzyka
- Kwestia (Title)
- Status (Select: Otwarte, Monitorowane, Zamknięte)
- Właściciel (Relation → Zespół)
- Wpływ (Select: Niski, Średni, Wysoki)
- Prawdopodobieństwo (Select: Niskie, Średnie, Wysokie)
- Score (Formula: patrz wcześniejszy wzór)
- Powiązane Zadania (Relation → Zadania)

## Materiały
- Materiał (Title)
- Status (Select: Do zamówienia, Zamówione, Dostarczone, Anulowane)
- Dostawca (URL/Text)
- Koszt netto [PLN] (Number)
- VAT [%] (Number)
- Koszt brutto [PLN] (Formula: round(net*(1+VAT/100),2))
- Powiązane Zadania (Relation → Zadania)

## Zespół
- Imię i Nazwisko (Title)
- Rola (Select)
- Kontakt (Email/Phone)
- Aktywny (Checkbox)
```

---

# ⚡ 10) Przykładowe flowy n8n (import) – `config/n8n/flows/escalation.json`

*(to minimalistyczny szablon — w n8n wybierz „Import from file” i uzupełnij NOTION\_DB\_ID, NOTION\_TOKEN w Credentials)*

```json
{
  "name": "BWS - Eskalacja zablokowanych",
  "nodes": [
    {
      "parameters": {
        "triggerTimes": { "item": [{ "mode": "everyHour" }] }
      },
      "id": "cron1",
      "name": "Co 1h",
      "type": "n8n-nodes-base.cron",
      "typeVersion": 1,
      "position": [200, 300]
    },
    {
      "parameters": {
        "resource": "database",
        "operation": "query",
        "databaseId": "NOTION_DB_ZADANIA_ID",
        "filters": [],
        "options": {}
      },
      "id": "notionQuery",
      "name": "Query Zadania",
      "type": "n8n-nodes-base.notion",
      "typeVersion": 2,
      "position": [400, 300],
      "credentials": { "notionApi": { "id": "your-cred-id", "name": "Notion API" } }
    },
    {
      "parameters": {
        "functionCode": "return items.filter(i => (i.json.properties?.Status?.select?.name === 'Zablokowane'));"
      },
      "id": "filterBlocked",
      "name": "Filtr Zablokowane",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [600, 300]
    },
    {
      "parameters": {
        "text": "Zadania zablokowane: {{$json.properties['Nazwa Zadania'].title[0].plain_text}}",
        "channel": "#project-alerts"
      },
      "id": "slackMsg",
      "name": "Slack Alert",
      "type": "n8n-nodes-base.slack",
      "typeVersion": 1,
      "position": [800, 300],
      "credentials": { "slackApi": { "id": "your-slack-cred-id", "name": "Slack API" } }
    }
  ],
  "connections": {
    "Co 1h": { "main": [[{ "node": "Query Zadania", "type": "main", "index": 0 }]] },
    "Query Zadania": { "main": [[{ "node": "Filtr Zablokowane", "type": "main", "index": 0 }]] },
    "Filtr Zablokowane": { "main": [[{ "node": "Slack Alert", "type": "main", "index": 0 }]] }
  }
}
```

Drugi flow „materials\_unlock.json” może po zmianie „Materiały.Status=Dostarczone” wyszukiwać powiązane zadania i ustawiać `Status=Do zrobienia`.

---

## Jak to odpalić „jak dla 6‑latka”

1. **Pobierz repo (stwórz folder) i wklej pliki jak wyżej.**
2. `cp .env.example .env` → otwórz `.env` i wklej swój `NOTION_TOKEN` oraz ewentualnie `NOTION_BASE_PAGE_ID`.
3. `chmod +x scripts/*.sh`
4. **Installer**: `./scripts/install.sh`
5. Otwórz **Cursor → Settings → MCP** i dodaj `config/cursor.mcp.json`.
6. W **Cursor** spróbuj komend MCP (tworzenie i wyszukiwanie zadań).
7. Wejdź na `http://localhost:5678` i zaimportuj flow n8n.

---

## Co mogę jeszcze zrobić (od razu, w tej samej wiadomości)?

* Dorzucić **gotowe CSV** z 21 zadaniami BWS (z terminami i zależnościami) do importu w Notion.
* Napisać **gotowe polecenia MCP** (JSON-y) tworzące wszystkie zadania i relacje „Zależy od”.
* Dodać **konfigurację reverse proxy (Caddy/Nginx)** jeśli chcesz wystawić n8n/MCP na HTTPS.
* Przygotować **checklistę QA** i **raport dzienny** (n8n) generowany do strony „Raport Dzienny” w Notion.

Powiedz słowo, a dorzucę wybrane elementy (albo wszystkie).

---

* Get 300 Notion Templates — [Grab Yours Now!](https://sparxno.gumroad.com/l/notion-templates-bundle/BUNDLE?utm_source=custom-gpt&utm_medium=chatgpt&utm_campaign=notion-templates-creator)
