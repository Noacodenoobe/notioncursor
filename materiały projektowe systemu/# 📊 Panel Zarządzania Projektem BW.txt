# 📊 Panel Zarządzania Projektem: BWS Kielce

## 🚀 Szybki Dostęp
- [📋 Zadania](#-zadania)
- [⚠️ Ryzyka i Otwarte Kwestie](#%EF%B8%8F-ryzyka-i-otwarte-kwestie)
- [📦 Materiały](#-materia%C5%82y)
- [👥 Zespół i Kontakty](#-zesp%C3%B3%C5%82-i-kontakty)

---

## 📋 Zadania
**Baza danych (Table)**

**Kolumny:**
- `Nazwa Zadania` (Title)
- `Status` (Select: Do zrobienia, W toku, Zakończone, Zablokowane)
- `Osoba Odpowiedzialna` (Relation → Zespół)
- `Termin` (Date)
- `Zależy od` (Relation → Zadania)
- `Blokuje` (Relation → Zadania)
- `Powiązane Ryzyka` (Relation → Ryzyka i Otwarte Kwestie)
- `Powiązane Materiały` (Relation → Materiały)

**Widoki:**
- ✅ Do zrobienia (Tydzień)
- 📌 Kanban wg Statusu
- 📑 Wszystkie zadania

---

## ⚠️ Ryzyka i Otwarte Kwestie
**Baza danych (Table)**

**Kolumny:**
- `Kwestia` (Title)
- `Status` (Select: Otwarte, Zamknięte, Monitorowane)
- `Właściciel` (Relation → Zespół)
- `Wpływ` (Select: Niski, Średni, Wysoki)
- `Powiązane Zadania` (Relation → Zadania)

**Widoki:**
- 🔴 Wysokie Ryzyka
- 🟡 Otwarte kwestie

---

## 📦 Materiały
**Baza danych (Table)**

**Kolumny:**
- `Materiał` (Title)
- `Status` (Select: Do zamówienia, Zamówione, Dostarczone)
- `Dostawca` (Text/URL)
- `Koszt` (Number)
- `Powiązane Zadania` (Relation → Zadania)

**Widoki:**
- 📌 Do zamówienia
- 📦 Wszystkie materiały

---

## 👥 Zespół i Kontakty
**Baza danych (Table)**

**Kolumny:**
- `Imię i Nazwisko` (Title)
- `Rola` (Select: Kierownik, Projektant, Dostawca, itd.)
- `Kontakt` (Email/Telefon)

**Widoki:**
- 👤 Zespół
- 🏗 Dostawcy

---

## 🔗 Relacje między bazami
- Zadanie ↔ Zadanie (`Zależy od`, `Blokuje`)
- Zadanie ↔ Ryzyko (`Powiązane Ryzyka`)
- Zadanie ↔ Materiał (`Powiązane Materiały`)
- Zadanie ↔ Zespół (`Osoba Odpowiedzialna`)
- Ryzyko ↔ Zespół (`Właściciel`)
