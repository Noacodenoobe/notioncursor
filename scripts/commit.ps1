# Skrypt do tworzenia commitów z polskimi opisami
# Użycie: .\scripts\commit.ps1 "Opis zmian"

param(
    [Parameter(Mandatory=$true)]
    [string]$CommitMessage
)

Write-Host "📝 Tworzę commit: $CommitMessage" -ForegroundColor Blue

# Dodaj wszystkie zmiany
git add .

# Utwórz commit
git commit -m "$CommitMessage"

Write-Host "✅ Commit utworzony: $CommitMessage" -ForegroundColor Green
Write-Host "💡 Aby wysłać na GitHub: git push origin main" -ForegroundColor Yellow
