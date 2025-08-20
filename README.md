# BWS Stack - Business Workflow System

A comprehensive stack for business workflow automation integrating Notion, n8n, Ollama, and vector databases.

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

## 🔧 Configuration

1. Copy the environment file:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` with your configuration:
   - Notion API keys and database IDs
   - Database passwords
   - n8n credentials

3. Configure Cursor MCP (optional):
   - Copy `config/cursor.mcp.json` to Cursor settings

## 📁 Project Structure

```
bws-stack/
├─ docker-compose.yml          # Main stack configuration
├─ env.example                 # Environment variables template
├─ Makefile                    # Convenience commands
├─ README.md                   # This file
├─ config/
│  ├─ cursor.mcp.json          # Cursor MCP configuration
│  ├─ n8n/
│  │  └─ flows/                # n8n workflow definitions
│  └─ notion/
│     └─ db_properties.md      # Notion database mappings
└─ scripts/
   ├─ install.sh               # Main installer script
   ├─ checks.sh                # Dependency checks
   ├─ pull_models.sh           # Ollama model downloader
   └─ health.sh                # Health check script
```

## 🎯 Available Commands

```bash
make help          # Show all available commands
make install       # Install and setup the stack
make start         # Start all services
make stop          # Stop all services
make restart       # Restart all services
make logs          # Show service logs
make clean         # Remove all containers and volumes
make pull-models   # Download Ollama models
make health-check  # Check service health
make setup         # Quick install + start + health check
```

## 🔗 Service URLs

After starting the stack:

- **n8n**: http://localhost:5678
- **Ollama API**: http://localhost:11434
- **Qdrant**: http://localhost:6333
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📊 Notion Integration

The stack includes predefined workflows for:

- **Task Escalation** - Automatic escalation of blocked tasks
- **Material Unlocking** - Conditional material access based on task completion

See `config/notion/db_properties.md` for database field mappings.

## 🤖 AI Features

- Local LLM inference with Ollama
- Vector embeddings storage with Qdrant
- Automated workflow triggers
- Intelligent task routing

## 🛠️ Development

### Adding New Workflows

1. Create workflow in n8n UI
2. Export to `config/n8n/flows/`
3. Update documentation

### Customizing Notion Integration

1. Update `config/notion/db_properties.md`
2. Modify n8n workflows accordingly
3. Test with sample data

## 🔍 Troubleshooting

### Common Issues

1. **Port conflicts**: Check `scripts/checks.sh` for port availability
2. **Permission errors**: Ensure scripts are executable (`chmod +x scripts/*.sh`)
3. **Service startup failures**: Check logs with `make logs`

### Health Checks

Run `make health-check` to verify all services are running correctly.

## 📝 License

[Add your license information here]

## 🤝 Contributing

[Add contribution guidelines here]
