# BWS Stack - Business Workflow System

A comprehensive stack for business workflow automation integrating Notion, n8n, Ollama, an AI Bridge (FastAPI), and vector databases.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd bws-stack

# Run the installer (one command setup)
make install

# Or use the quick setup
make setup
```

## 📋 Prerequisites

- Docker & Docker Compose
- Git
- Make (optional, for convenience commands)

## 🏗️ Architecture

The BWS Stack consists of:

- **PostgreSQL** - Primary database
- **Redis** - Caching layer
- **n8n** - Workflow automation platform
- **Ollama** - Local LLM inference
- **Qdrant** - Vector database for embeddings
- **AI Bridge** - FastAPI microservice for embeddings/RAG

## 🔧 Configuration

1. Copy the environment file:
   ```bash
   cp env.example .env
   ```