# 📊 Podsumowanie projektu DomenaRynku.pl

## 🎯 Cel projektu

**DomenaRynku.pl** to profesjonalny portal finansowy dla świadomych inwestorów, skupiony na analizie Giełdy Papierów Wartościowych w Warszawie. Projekt wyróżnia się **unikalnymi wskaźnikami analitycznymi**, które wykraczają poza standardowe dane finansowe dostępne w innych serwisach.

**Główne cele:**
- Dostarczanie autorskich wskaźników analitycznych (indeks trendów, sentyment rynku)
- Analiza szerokości rynku (market breadth) jako wyprzedzającego wskaźnika zmian trendu
- Edukacja inwestorska oparta na danych ilościowych
- Wykrywanie dywergencji między głównymi indeksami a szerokością rynku

## ⚙️ Jak działa projekt

### Architektura techniczna

- **Frontend**: Quarto (system generowania statycznych stron z R/Python)
- **Backend analityczny**: R z modułami analitycznymi (pakiet `box` do modularyzacji)
- **Hosting**: Netlify z automatycznym deploymentem z GitHub
- **Domena**: domenarynku.pl (własna)
- **Dane**: Web scraping z Stooq, Biznesradar + przetwarzanie w R

### Workflow przetwarzania danych

1. **Pozyskiwanie**: Skrypty R pobierają dane cenowe z API Stooq (funkcja `stooq_dw()`)
2. **Przetwarzanie**: Obliczanie wskaźników (SMA, EMA, trend analysis) z użyciem xts/zoo
3. **Indeksacja**: Tworzenie równoważonych indeksów (każda spółka = 1 udział, nie kapitalizacja)
4. **Zapis**: Dane przetworzone zapisywane jako .RDS w katalogu `data/`
5. **Wizualizacja**: Quarto renderuje strony z interaktywnymi wykresami Plotly
6. **Deployment**: Push do GitHub → automatyczny build na Netlify → publikacja

### Kluczowa innowacja metodologiczna

- Indeksy równoważone vs kapitalizacyjne (WIG/WIG20)
- Logarytmiczne zwroty dla poprawnej agregacji: `diff(log(prices))` → `exp(cumsum())`
- Market breadth: % spółek w trendzie wzrostowym (SMA2 > SMA200)

## 🔍 Aspekty SEO

### 1. Struktura techniczna SEO

- ✅ Canonical URLs automatycznie generowane przez Quarto
- ✅ Meta tagi `description` i `keywords` na każdej stronie
- ✅ Open Graph i Twitter Card dla social media
- ✅ Semantyczna struktura HTML5
- ✅ Responsywny design (mobile-friendly)
- ✅ Sitemap.xml generowany automatycznie

### 2. Google Tag Manager + Consent Mode v2

```javascript
// Implementacja GDPR-compliant tracking
gtag('consent', 'default', {
  'analytics_storage': 'denied',  // Domyślnie zablokowane
  'ad_storage': 'denied'
});
```

### 3. Cookie Consent (Klaro)

- Pełna zgodność z GDPR
- Integracja z Google Consent Mode v2
- Polskie tłumaczenia wszystkich komunikatów
- Zarządzanie kategoriami: Analytics, Marketing, Personalizacja, Social Media

### 4. Optymalizacja treści

- **Długie słowa kluczowe (long-tail)**: "indeks trendów GPW", "market breadth indicator polska", "szerokość rynku warszawa"
- **Unikalne tytuły stron**: `pagetitle` różny od `title` dla lepszego SEO
- **Strukturalne nagłówki**: H1 → H2 → H3 (hierarchia treści)
- **Aktualność**: `date-modified: last-modified` dla sygnalizacji freshness

### 5. Performance

- CSS/JS minifikacja przez Netlify
- Kompresja obrazów
- Freeze execution (cache wyników R dla szybszego buildu)
- CDN Netlify (globalna dystrybucja)

## 📁 Struktura podstron

```
domenarynku.pl/
├── index.qmd                    # Strona główna - listing postów
├── about.qmd                    # O nas
├── spolki-gpw.qmd              # Baza spółek (w rozwoju)
│
├── indeksy/
│   ├── indeks-trendow-gpw.qmd         # Indeks trendów (market breadth)
│   └── indeks-cenowy-top100.qmd       # Indeks cenowy równoważony top100
│
├── sentyment-rynku/
│   ├── polska.qmd                     # Sentyment rynku GPW
│   ├── usa.qmd                        # Sentyment USA (S&P500)
│   └── swiat.qmd                      # Sentyment globalny (placeholder)
│
└── posts/
    └── 2024-11-21-indeks-trendow-analiza/
        └── index.qmd                   # Analiza dywergencji listopad 2024
```

### Opis kluczowych sekcji

#### 1. Strona główna (`index.qmd`)
- Listing blogowych analiz rynkowych
- Gradient header (niebieski → niebieski jasny)
- Automatyczne wyświetlanie najnowszych postów

#### 2. Indeks trendów GPW (`indeksy/indeks-trendow-gpw.qmd`)
- **Kluczowy wskaźnik**: % spółek z top100 w trendzie wzrostowym
- Interaktywny wykres Plotly (250 ostatnich sesji)
- Porównanie z WIG i WIG20 (znormalizowane 0-100)
- Analiza korelacji i dywergencji
- Tabele statystyk: średnia, mediana, Q1/Q3

#### 3. Indeks cenowy top100 (`indeksy/indeks-cenowy-top100.qmd`)
- Równoważony indeks cenowy (każda spółka = 1 udział)
- Alternatywa dla kapitalizacyjnych WIG/WIG20
- Pokazuje "demokratyczną" siłę rynku

#### 4. Sentyment rynku Polska (`sentyment-rynku/polska.qmd`)
- Wskaźnik nastrojów inwestorów 0-100
- Źródło: analiza danych z FW20 (kontrakty terminowe)
- Wykrywanie ekstremalnych poziomów (overbought/oversold)

#### 5. Sentyment USA (`sentyment-rynku/usa.qmd`)
- Analogiczny wskaźnik dla rynku amerykańskiego
- Porównanie z S&P500
- Korelacje między rynkami

#### 6. Spółki GPW (`spolki-gpw.qmd`)
- W fazie rozwoju
- Planowana baza 100 profili spółek
- Unikalne opisy biznesowe (nie copy-paste)

#### 7. Blog/Posty
- Regularne analizy rynkowe
- Szablon: Wprowadzenie → Wykresy → Analiza → Wnioski
- Neutralny język inwestycyjny ("można rozważyć" vs "kup/sprzedaj")

## 🎨 Design i branding

### Kolorystyka (style.css)

```css
--primary-blue: #1e3a8a      /* Główny niebieski (ciemny) */
--accent-blue: #3b82f6       /* Akcent niebieski (jasny) */
--light-blue: #93c5fd        /* Hover states */
--gray-text: #64748b         /* Tekst pomocniczy */
--dark-text: #1e293b         /* Tekst główny */
```

### Charakterystyczne elementy

- Gradient navbar: `linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)`
- Białe logo (SVG) na ciemnym tle
- Karty z cieniem i hover effect (transform: translateY(-4px))
- Border-left: 4px solid blue na kartach postów
- Profesjonalny, finansowy wygląd

### Typografia

- Font: Segoe UI (system fonts dla szybkości)
- H1: 2.5rem, border-bottom niebieskie
- H2: 2rem, kolor accent-blue
- Line-height: 1.7 (czytelność)

## 📊 Dane i integracje

### Pliki danych w `data/`

- `index_trend.RDS` - Indeks trendów + WIG/WIG20
- `index_price.RDS` - Indeks cenowy równoważony
- `index_unweighted.RDS` - Indeks niezważony
- `sentiment.RDS` - Sentyment PL
- `sentimentEN.RDS` - Sentyment USA
- `prices100.RDS` - Notowania top100 spółek
- `gpw_companies.RDS` - Metadane spółek
- `www_data2.RDS` - Dane ze stron spółek (scraping)
- `table_hrefs.RDS` - Linki do stron spółek
- `branze_podbranze.csv` - Klasyfikacja sektorowa

### Skrypty R w `R/`

- `calc_trend_index.R` - Obliczanie indeksu trendów
- `calc_price_index.R` - Indeks cenowy
- `data_sentiment_prep.R` - Przetwarzanie sentymentu PL
- `data_sentiment_prepEN.R` - Sentyment USA
- `get_prices2.R` - Pobieranie notowań
- `read_companies_websites.R` - Scraping stron spółek
- `mod/gpw.R` - Moduł główny z funkcjami pomocniczymi

## 🔐 Bezpieczeństwo i separacja

### Strategia bezpieczeństwa

- ✅ Repozytorium publiczne zawiera tylko kod generowania strony
- ✅ Skrypty akwizycji danych (z kluczami API) w prywatnym repo
- ✅ Dane przetworzone (.RDS) publikowane, surowe - NIE
- ✅ `.gitignore` chroni wrażliwe pliki

### Prywatne vs Publiczne

```
PUBLICZNE (GitHub):
- Kod Quarto (.qmd)
- Skrypty analizy (R/)
- Przetworzone dane (data/*.RDS)
- Konfiguracja (YAML, CSS, JS)

PRYWATNE (lokalne):
- Klucze API
- Skrypty web scrapingu surowego
- Hasła, tokeny
- Surowe dane przed czyszczeniem
```

## 📈 Kluczowe wskaźniki i metodologia

### Indeks trendów GPW (Market Breadth Indicator)

**Definicja**: Procent spółek z top 100 GPW, które znajdują się w trendzie wzrostowym

**Metodologia:**
```r
# Dla każdej spółki:
SMA_2 <- SMA(price, 2)      # Krótkoterminowa średnia
SMA_200 <- SMA(price, 200)  # Długoterminowa średnia

# Spółka w trendzie wzrostowym gdy:
is_uptrend <- SMA_2 > SMA_200

# Indeks = % spółek w trendzie wzrostowym
index_trend <- sum(is_uptrend) / total_companies * 100
```

**Interpretacja:**
- > 70% - Silny rynek byka (broad rally)
- 50-70% - Umiarkowana hossa
- 30-50% - Neutralny/mieszany
- < 30% - Rynek niedźwiedzia

**Sygnały dywergencji:**
- WIG/WIG20 rośnie, ale indeks trendów spada → Ostrzeżenie przed korektą
- WIG/WIG20 spada, ale indeks trendów rośnie → Potencjalne dno rynku

### Indeks cenowy równoważony

**Różnica vs WIG/WIG20:**
- WIG/WIG20: Waga = kapitalizacja spółki (duże firmy dominują)
- Indeks równoważony: Każda spółka ma równy udział (1/100)

**Obliczanie:**
```r
# 1. Logarytmiczne zwroty dla każdej spółki
log_returns <- diff(log(prices))

# 2. Średnia zwrotów (równe wagi)
avg_return <- rowMeans(log_returns, na.rm = TRUE)

# 3. Kumulatywny indeks
index <- exp(cumsum(avg_return)) * 100
```

**Zastosowanie:**
- Pokazuje "demokratyczną" kondycję rynku
- Wykrywa czy wzrost jest szerokim trendem czy tylko kilka spółek

### Sentyment rynku

**Źródła danych:**
- Polska: Kontrakty FW20 (futures)
- USA: Opcje S&P500, VIX

**Normalizacja 0-100:**
```r
# Min-max normalization
sentiment_norm <- (sentiment - min(sentiment)) / 
                  (max(sentiment) - min(sentiment)) * 100
```

**Interpretacja:**
- > 80 - Ekstremalna euforia (potencjalny szczyt)
- 50-80 - Optymizm
- 20-50 - Pesymizm
- < 20 - Panika (potencjalne dno)

## 🛠️ Stack technologiczny

### Frontend & Generowanie
- **Quarto 1.4+** - Static site generator
- **R 4.5.2** - Język analiz
- **RStudio** - IDE

### Pakiety R
```r
# Analiza danych
- tidyverse (dplyr, ggplot2, tidyr, purrr)
- xts, zoo - Serie czasowe
- quantmod, TTR - Analiza techniczna
- PerformanceAnalytics - Metryki

# Web scraping
- rvest - HTML parsing
- httr - HTTP requests
- jsonlite - JSON parsing

# Wizualizacja
- plotly - Interaktywne wykresy
- kableExtra - Tabele HTML

# Modularyzacja
- box - Modułowy system importów
```

### Deployment & Infrastructure
- **GitHub** - Version control (publiczne repo)
- **Netlify** - Hosting + CI/CD
- **Cloudflare DNS** - Zarządzanie domeną
- **Google Tag Manager** - Analytics
- **Klaro** - Cookie consent

### Narzędzia SEO
- Quarto canonical URLs
- Open Graph meta tags
- Google Search Console
- Google Analytics 4 (GA4)

## 📝 Konwencje i best practices

### Nazewnictwo plików

```
# Strony Quarto
nazwa-strony.qmd          # kebab-case

# Posty blogowe
YYYY-MM-DD-tytul/index.qmd

# Skrypty R
verb_noun.R               # snake_case
calc_trend_index.R
read_companies_websites.R

# Dane
description.RDS           # snake_case
index_trend.RDS
prices100.RDS
```

### Struktura pliku .qmd

```yaml
---
# === Wyświetlane na stronie ===
title: "Tytuł widoczny na stronie"
subtitle: "Podtytuł"
date: "2024-11-21"
date-modified: last-modified

# === SEO - Meta tagi w <head> ===
pagetitle: "Tytuł dla SEO + Branding | DomenaRynku.pl"
format:
  html:
    header-includes: |
      <meta name="description" content="Opis 150-160 znaków dla Google">
      <meta name="keywords" content="słowa, kluczowe, rozdzielone, przecinkami">
---
```

### Język w analizach

**❌ Unikać:**
- "Kup teraz!"
- "To jest świetna okazja!"
- "Gwarantowany zysk"

**✅ Zalecane:**
- "Dane sugerują..."
- "Można rozważyć..."
- "Warto zwrócić uwagę na..."
- "Historycznie taki poziom często poprzedzał..."

### Git workflow

```bash
# Aktualizacja danych
Rscript R/calc_trend_index.R
Rscript R/calc_price_index.R

# Render strony lokalnie
quarto render

# Commit i push
git add .
git commit -m "Update: dane 2026-02-03"
git push origin main

# Netlify automatycznie zbuduje i wdroży
```

## 🚀 Roadmap i dalszy rozwój

### Krótkoterminowe (Q1 2026)
- [ ] Uzupełnienie 100 profili spółek z unikalnymi opisami
- [ ] Szablon postów dla regularnych analiz (weekly/monthly)
- [ ] Rozbudowa sekcji sentymentu USA
- [ ] Fix Google Analytics (weryfikacja konfiguracji)

### Średnioterminowe (Q2-Q3 2026)
- [ ] Newsletter email z cotygodniowymi analizami
- [ ] Screener spółek (filtrowanie po kryteriach)
- [ ] Alerty email przy ekstremalnych poziomach sentymentu
- [ ] Sekcja edukacyjna (jak czytać wskaźniki)
- [ ] API publiczne dla deweloperów (read-only)

### Długoterminowe (2027+)
- [ ] Aplikacja mobilna (PWA)
- [ ] Rozbudowa o rynki europejskie
- [ ] Machine learning: predykcja punktów zwrotnych
- [ ] Premium subscription (zaawansowane narzędzia)
- [ ] Community forum dla inwestorów

## 🐛 Znane problemy i rozwiązania

### Problem 1: Timeout przy scrapingu stron spółek
**Objaw:** `Error: Timeout was reached`

**Rozwiązanie:**
```r
# Użycie purrr::possibly() dla graceful failure
safe_scrape <- possibly(scrape_function, otherwise = NA)
results <- map(urls, safe_scrape)
```

### Problem 2: Google Analytics nie pokazuje danych
**Status:** W trakcie debugowania

**Do sprawdzenia:**
- Czy GTM container ID jest poprawny
- Czy Consent Mode v2 poprawnie aktualizuje zgody
- Czy filtr IP nie blokuje własnego ruchu

### Problem 3: Freeze execution spowalnia development
**Rozwiązanie:**
```bash
# Wymuś re-render bez cache
quarto render --execute-dir . --execute-daemon-restart
```

### Problem 4: Brakujące dane dla niektórych spółek
**Przyczyna:** Spółka ma < 250 dni historii notowań

**Rozwiązanie:**
```r
# W calc_trend_index.R
min_history_days <- 250
for(col in colnames(price_xts)) {
  valid_data <- sum(!is.na(price_xts[, col]))
  if(valid_data < min_history_days) {
    price_xts <- price_xts[, colnames(price_xts) != col]
  }
}
```

## 📚 Dodatkowe zasoby

### Dokumentacja
- [Quarto Documentation](https://quarto.org/docs/)
- [Plotly R Documentation](https://plotly.com/r/)
- [Netlify Docs](https://docs.netlify.com/)
- [Google Consent Mode v2](https://support.google.com/analytics/answer/9976101)

### Inspiracje i źródła wiedzy
- Investopedia - Definicje wskaźników technicznych
- StockCharts.com - Market breadth indicators
- TradingView - Charting ideas
- AAII Sentiment Survey - Metodologia sentymentu

### Społeczność
- r/algotrading (Reddit)
- Quantitative Finance Stack Exchange
- R for Data Science Community

---

**Data utworzenia dokumentu:** 2026-02-03  
**Ostatnia aktualizacja:** 2026-02-03  
**Status projektu:** ✅ **LIVE** na https://domenarynku.pl  
**Autor:** DomenaRynku.pl Team

