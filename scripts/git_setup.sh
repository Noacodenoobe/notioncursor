#!/bin/bash

# Skrypt konfiguracji Git dla projektu BWS Stack
# Automatyzuje proces inicjalizacji repozytorium i pierwszego commita

set -e

# Kolory dla output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcje do kolorowego output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Konfiguracja repozytorium Git dla BWS Stack..."

# Sprawdź czy Git jest zainstalowany
if ! command -v git >/dev/null 2>&1; then
    print_error "Git nie jest zainstalowany. Zainstaluj Git i spróbuj ponownie."
    exit 1
fi

# Sprawdź czy jesteśmy w katalogu projektu
if [ ! -f "docker-compose.yml" ] || [ ! -f "README.md" ]; then
    print_error "Nie jesteś w katalogu projektu BWS Stack. Przejdź do katalogu z docker-compose.yml"
    exit 1
fi

# Inicjalizuj repozytorium Git
if [ ! -d ".git" ]; then
    print_status "Inicjalizuję repozytorium Git..."
    git init
    print_success "Repozytorium Git zainicjalizowane"
else
    print_status "Repozytorium Git już istnieje"
fi

# Dodaj remote origin
print_status "Konfiguruję remote origin..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/Noacodenoobe/notioncursor.git
print_success "Remote origin skonfigurowany"

# Utwórz .gitignore
print_status "Tworzę plik .gitignore..."
cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.production

# Docker volumes
data/
volumes/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Node modules (if any)
node_modules/

# Python cache
__pycache__/
*.pyc
*.pyo

# Backup files
*.bak
*.backup
EOF
print_success "Plik .gitignore utworzony"

# Dodaj wszystkie pliki
print_status "Dodaję pliki do staging area..."
git add .

# Utwórz pierwszy commit
print_status "Tworzę pierwszy commit..."
git commit -m "🎉 Inicjalizacja projektu BWS Stack

Dodano kompletny stack do automatyzacji workflow biznesowego:

📦 Główne komponenty:
- Docker Compose z PostgreSQL, Redis, n8n, Ollama, Qdrant
- Skrypty instalacyjne i health check
- Konfiguracja MCP dla Cursor
- Workflow n8n dla eskalacji zadań i odblokowywania materiałów
- Mapowanie pól baz danych Notion

🔧 Funkcjonalności:
- Automatyczna eskalacja zablokowanych zadań
- Odblokowywanie materiałów po ukończeniu zadań
- Integracja z Notion API
- Lokalne modele AI z Ollama
- Baza wektorowa Qdrant

📁 Struktura:
- config/ - konfiguracje i workflow
- scripts/ - skrypty instalacyjne
- docker-compose.yml - główna konfiguracja stacku
- Makefile - komendy pomocnicze

🚀 Gotowe do uruchomienia: make install"
print_success "Pierwszy commit utworzony"

# Utwórz skrypt do przyszłych commitów
print_status "Tworzę skrypt do commitów..."
cat > scripts/commit.sh << 'EOF'
#!/bin/bash

# Skrypt do tworzenia commitów z polskimi opisami
# Użycie: ./scripts/commit.sh "Opis zmian"

set -e

if [ $# -eq 0 ]; then
    echo "Użycie: $0 \"Opis zmian\""
    echo "Przykład: $0 \"Dodano nowy workflow dla notyfikacji\""
    exit 1
fi

COMMIT_MESSAGE="$1"

# Dodaj wszystkie zmiany
git add .

# Utwórz commit
git commit -m "$COMMIT_MESSAGE"

echo "✅ Commit utworzony: $COMMIT_MESSAGE"
echo "💡 Aby wysłać na GitHub: git push origin main"
EOF

chmod +x scripts/commit.sh
print_success "Skrypt commit.sh utworzony"

# Utwórz skrypt do push
cat > scripts/push.sh << 'EOF'
#!/bin/bash

# Skrypt do wysyłania zmian na GitHub

set -e

echo "🚀 Wysyłam zmiany na GitHub..."

# Sprawdź czy jesteśmy na main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Jesteś na branch: $CURRENT_BRANCH"
    echo "💡 Aby przełączyć na main: git checkout main"
    exit 1
fi

# Push na GitHub
git push origin main

echo "✅ Zmiany wysłane na GitHub!"
echo "🔗 Repozytorium: https://github.com/Noacodenoobe/notioncursor"
EOF

chmod +x scripts/push.sh
print_success "Skrypt push.sh utworzony"

print_success "Konfiguracja Git zakończona!"

echo ""
echo "📋 Następne kroki:"
echo "1. Sprawdź status: git status"
echo "2. Wyślij na GitHub: git push origin main"
echo "3. Dla przyszłych commitów: ./scripts/commit.sh \"Opis zmian\""
echo "4. Dla push: ./scripts/push.sh"
echo ""
echo "🔗 Repozytorium: https://github.com/Noacodenoobe/notioncursor"
echo ""
