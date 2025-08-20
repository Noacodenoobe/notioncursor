# Skrypt do wysyłania zmian na GitHub

Write-Host "🚀 Wysyłam zmiany na GitHub..." -ForegroundColor Blue

# Sprawdź czy jesteśmy na main branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Host "⚠️  Jesteś na branch: $currentBranch" -ForegroundColor Yellow
    Write-Host "💡 Aby przełączyć na main: git checkout main" -ForegroundColor Yellow
    exit 1
}

# Push na GitHub
git push origin main

Write-Host "✅ Zmiany wysłane na GitHub!" -ForegroundColor Green
Write-Host "🔗 Repozytorium: https://github.com/Noacodenoobe/notioncursor" -ForegroundColor Cyan
