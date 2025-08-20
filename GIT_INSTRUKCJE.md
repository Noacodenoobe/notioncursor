# 📚 Instrukcje Git dla projektu BWS Stack

## 🎉 Sukces! Repozytorium Git zostało skonfigurowane

Twoje repozytorium jest teraz połączone z GitHubem: https://github.com/Noacodenoobe/notioncursor.git

## 🚀 Jak wysłać zmiany na GitHub

### Opcja 1: Użyj skryptów PowerShell (zalecane)

```powershell
# Utworzenie commita z polskim opisem
.\scripts\commit.ps1 "Opis Twoich zmian"

# Wysłanie na GitHub
.\scripts\push.ps1
```

### Opcja 2: Komendy Git bezpośrednio

```powershell
# Dodaj wszystkie zmiany
git add .

# Utwórz commit z polskim opisem
git commit -m "🎉 Opis Twoich zmian"

# Wyślij na GitHub
git push origin main
```

### Opcja 3: Użyj Makefile

```powershell
# Utworzenie commita
make git-commit MESSAGE="Opis zmian"

# Wysłanie na GitHub
make git-push
```

## 📝 Przykłady commitów w języku polskim

```powershell
# Dodanie nowej funkcjonalności
.\scripts\commit.ps1 "✨ Dodano nowy workflow dla notyfikacji email"

# Naprawa błędu
.\scripts\commit.ps1 "🐛 Naprawiono problem z konfiguracją n8n"

# Aktualizacja dokumentacji
.\scripts\commit.ps1 "📚 Zaktualizowano README z nowymi instrukcjami"

# Refaktoryzacja kodu
.\scripts\commit.ps1 "♻️ Przepisano skrypty instalacyjne"

# Dodanie nowych plików
.\scripts\commit.ps1 "📁 Dodano nowe konfiguracje dla Ollama"
```

## 🔧 Przydatne komendy Git

```powershell
# Sprawdź status
git status

# Zobacz historię commitów
git log --oneline

# Sprawdź remote
git remote -v

# Przełącz na main branch
git checkout main

# Pobierz zmiany z GitHub
git pull origin main
```

## ⚠️ Ważne uwagi

1. **Zawsze używaj polskich opisów** w commitach
2. **Używaj emoji** dla lepszej czytelności
3. **Opisuj konkretnie** co zostało zmienione
4. **Commit często** - lepiej małe, częste commity niż duże, rzadkie

## 🎯 Workflow pracy

1. **Edytuj pliki** w projekcie
2. **Sprawdź status**: `git status`
3. **Utwórz commit**: `.\scripts\commit.ps1 "Opis zmian"`
4. **Wyślij na GitHub**: `.\scripts\push.ps1`
5. **Sprawdź na GitHub**: https://github.com/Noacodenoobe/notioncursor

## 🔗 Linki

- **Repozytorium**: https://github.com/Noacodenoobe/notioncursor
- **Dokumentacja Git**: https://git-scm.com/doc
- **GitHub Guides**: https://guides.github.com/

---

**Gotowe! 🎉** Twoje repozytorium jest skonfigurowane i gotowe do pracy z polskimi commitami.
