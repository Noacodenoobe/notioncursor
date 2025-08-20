# Skrypt konfiguracji Git dla projektu BWS Stack (PowerShell)
# Automatyzuje proces inicjalizacji repozytorium i pierwszego commita

param(
    [string]$CommitMessage = ""
)

# Funkcje do kolorowego output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

Write-Status "Konfiguracja repozytorium Git dla BWS Stack..."

# Sprawdź czy Git jest zainstalowany
try {
    git --version | Out-Null
} catch {
    Write-Error "Git nie jest zainstalowany. Zainstaluj Git i spróbuj ponownie."
    exit 1
}

# Sprawdź czy jesteśmy w katalogu projektu
if (-not (Test-Path "docker-compose.yml") -or -not (Test-Path "README.md")) {
    Write-Error "Nie jesteś w katalogu projektu BWS Stack. Przejdź do katalogu z docker-compose.yml"
    exit 1
}

# Inicjalizuj repozytorium Git
if (-not (Test-Path ".git")) {
    Write-Status "Inicjalizuję repozytorium Git..."
    git init
    Write-Success "Repozytorium Git zainicjalizowane"
} else {
    Write-Status "Repozytorium Git już istnieje"
}

# Dodaj remote origin
Write-Status "Konfiguruję remote origin..."
git remote remove origin 2>$null
git remote add origin https://github.com/Noacodenoobe/notioncursor.git
Write-Success "Remote origin skonfigurowany"

# Utwórz .gitignore
Write-Status "Tworzę plik .gitignore..."
@"
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
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
Write-Success "Plik .gitignore utworzony"

# Dodaj wszystkie pliki
Write-Status "Dodaję pliki do staging area..."
git add .

# Utwórz pierwszy commit
Write-Status "Tworzę pierwszy commit..."
$commitMsg = @"
🎉 Inicjalizacja projektu BWS Stack

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

🚀 Gotowe do uruchomienia: make install
"@

git commit -m $commitMsg
Write-Success "Pierwszy commit utworzony"

# Utwórz skrypt do przyszłych commitów (PowerShell)
Write-Status "Tworzę skrypt do commitów..."
@"
# Skrypt do tworzenia commitów z polskimi opisami (PowerShell)
# Użycie: .\scripts\commit.ps1 "Opis zmian"

param(
    [Parameter(Mandatory=`$true)]
    [string]`$CommitMessage
)

Write-Host "📝 Tworzę commit: `$CommitMessage" -ForegroundColor Blue

# Dodaj wszystkie zmiany
git add .

# Utwórz commit
git commit -m "`$CommitMessage"

Write-Host "✅ Commit utworzony: `$CommitMessage" -ForegroundColor Green
Write-Host "💡 Aby wysłać na GitHub: git push origin main" -ForegroundColor Yellow
"@ | Out-File -FilePath "scripts\commit.ps1" -Encoding UTF8

# Utwórz skrypt do push (PowerShell)
@"
# Skrypt do wysyłania zmian na GitHub (PowerShell)

Write-Host "🚀 Wysyłam zmiany na GitHub..." -ForegroundColor Blue

# Sprawdź czy jesteśmy na main branch
`$currentBranch = git branch --show-current
if (`$currentBranch -ne "main") {
    Write-Host "⚠️  Jesteś na branch: `$currentBranch" -ForegroundColor Yellow
    Write-Host "💡 Aby przełączyć na main: git checkout main" -ForegroundColor Yellow
    exit 1
}

# Push na GitHub
git push origin main

Write-Host "✅ Zmiany wysłane na GitHub!" -ForegroundColor Green
Write-Host "🔗 Repozytorium: https://github.com/Noacodenoobe/notioncursor" -ForegroundColor Cyan
"@ | Out-File -FilePath "scripts\push.ps1" -Encoding UTF8

Write-Success "Konfiguracja Git zakończona!"

Write-Host ""
Write-Host "📋 Następne kroki:" -ForegroundColor Cyan
Write-Host "1. Sprawdź status: git status" -ForegroundColor White
Write-Host "2. Wyślij na GitHub: git push origin main" -ForegroundColor White
Write-Host "3. Dla przyszłych commitów: .\scripts\commit.ps1 'Opis zmian'" -ForegroundColor White
Write-Host "4. Dla push: .\scripts\push.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Repozytorium: https://github.com/Noacodenoobe/notioncursor" -ForegroundColor Cyan
Write-Host ""
