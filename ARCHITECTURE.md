# BWS Stack Architecture

## Overview

Business Workflow System (BWS) łączy Notion, n8n, lokalne LLM (Ollama) oraz wektorową bazę Qdrant w celu automatyzacji przepływów pracy i wsparcia AI (RAG, podsumowania, reguły biznesowe). Ten dokument jest głównym plikiem architektury i jest aktualizowany co kilka kroków zmian (zgodnie z polityką non-destructive).

## Components

- PostgreSQL (primary relational database)
- Redis (caching / ephemeral queues)
- n8n (workflow automation engine)
- Ollama (local LLM inference + embeddings)
- Qdrant (vector database)
- AI Bridge (FastAPI microservice for embeddings, RAG, health)

## High-Level Architecture

```mermaid
flowchart LR
  subgraph Orchestration
    N8N[n8n Workflows]
  end

  subgraph AI
    AIB[AI Bridge (FastAPI)]
    OLL[Ollama]
    QDR[Qdrant]
  end

  subgraph Data
    PG[(PostgreSQL)]
    RED[(Redis)]
  end

  Notion[Notion API]

  N8N <--> Notion
  N8N --> AIB
  AIB <--> OLL
  AIB <--> QDR
  N8N <--> PG
  N8N <--> RED
```

## Data Flows

- Task Escalation: n8n cyklicznie odczytuje zadania z Notion, filtruje blokowane >7 dni, ustawia „Escalated” i tworzy wpis ryzyka.
- Materials Unlock: n8n iteruje po materiałach, sprawdza zależne zadania, odblokowuje i tworzy powiadomienie.
- RAG: AI Bridge indeksuje treści (embeddings via Ollama) do Qdrant i obsługuje wyszukiwanie semantyczne dla workflowów i integracji.

## Versions and Dependencies (pinning)

Wersje są parametryzowane zmiennymi środowiskowymi, domyślnie:

- POSTGRES_TAG=15-alpine
- REDIS_TAG=7.2-alpine
- N8N_TAG=1.76.0
- OLLAMA_TAG=0.3.12
- QDRANT_TAG=v1.8.4

AI Bridge (Python):

- Python 3.11
- fastapi, uvicorn, httpx, qdrant-client, pydantic, tenacity

## Environment

Kluczowe zmienne (wybór):

- NOTION_API_KEY, NOTION_DATABASE_ID_* (Tasks, Materials, Risks, Team)
- OLLAMA_HOST, OLLAMA_MODEL (np. llama2:7b), EMBEDDING_MODEL (np. nomic-embed-text:latest)
- QDRANT_HOST, QDRANT_PORT, QDRANT_COLLECTION (np. materials)
- APP_ENV, APP_DEBUG, LOG_LEVEL

## AI Bridge API (initial)

- GET /health – health check mikroserwisu
- POST /embed – wejście: list[str] → wyjście: list[vector]
- POST /ingest – zapis wektorów do Qdrant (collection, ids, payloads)
- POST /search – zapytanie semantyczne (text → nearest neighbors)

## Change Management & Safeguards (Non-destructive policy)

- Zero hard-delete bez pełnej weryfikacji zależności i backupu. Preferujemy soft-delete/archiwizację.
- Każda destrukcyjna zmiana musi mieć: pełny przegląd użyć, plan rollback, kopię zapasową.
- Workflowy n8n wersjonujemy (v2, v3…), nie nadpisujemy.
- Plik ARCHITECTURE.md i CHANGELOG.md aktualizujemy co 2–3 kroki (delta + wpływ + rollback).

## Coding Model Rules (skrót)

- Kod, nazwy i komentarze wyłącznie po angielsku; PEP 8, type hints, docstringi.
- Kontrola błędów: konkretne wyjątki, brak „gołych” exceptów, early return, płytka złożoność.
- Testy: jednostkowe dla AI Bridge; smoke testy health.

## Deployment

- Dev: docker compose (profile default), porty lokalne.
- Prod: pinned tags, secrets zarządzane poza repo, health checks, metryki, backupy.

## Roadmap (short)

1) Pinned versions + compose wrapper + AI Bridge (MVP)
2) n8n flows v2 (escalation, materials)
3) RAG indexing, kolekcje Qdrant, testy i lint
4) Observability (metrics), security hardening, MCP serwery

---

Changelog delta (initial):

- Added AI Bridge component and version pinning plan.
- Introduced non-destructive change policy and documentation cadence.
