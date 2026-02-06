# Dokumentacja projektu DomenaRynku.pl

**Portal dla świadomego inwestora — analiza GPW**  
**Adres:** https://domenarynku.pl  
**Status:** LIVE  
**Data dokumentu:** 2026-02-06

---

## 1. Cel projektu

DomenaRynku.pl to portal finansowy poświęcony analizie Giełdy Papierów Wartościowych w Warszawie. Wyróżnia się autorskimi wskaźnikami analitycznymi, których nie znajdziesz w typowych serwisach giełdowych. Projekt łączy analizę ilościową (quantitative analysis) z przystępną edukacją inwestorską.

Główne wartości:

- Autorski **Indeks Trendów GPW** — wskaźnik szerokości rynku (market breadth indicator) pokazujący, jaki procent spółek znajduje się w trendzie wzrostowym.
- **Indeks cenowy równoważony** — inspirowany metodyką Martina Zweiga (ZUPI z książki "Winning on Wall Street"), gdzie każda spółka ma równą wagę niezależnie od kapitalizacji.
- **Analiza sentymentu** rynku polskiego i amerykańskiego na bazie analizy nagłówków prasowych.
- **Analiza dywergencji** między wskaźnikami breadth a głównymi indeksami (WIG, WIG20) jako sygnały wyprzedzające zmiany trendów.
- Neutralny język inwestycyjny ("można rozważyć", "dane sugerują" zamiast "kup/sprzedaj").

---

## 2. Architektura techniczna

### Stack technologiczny

| Warstwa | Technologia |
|---------|-------------|
| Generowanie strony | **Quarto 1.4+** (static site generator z R) |
| Język analiz | **R 4.5.2** |
| IDE | **RStudio** |
| Hosting | **Netlify** (automatyczny deploy z GitHub) |
| Domena | **domenarynku.pl** (zarejestrowana w Netlify) |
| Repo kodu | **GitHub** (publiczne repozytorium) |
| Analytics | **Google Analytics 4** via **Google Tag Manager** |
| Cookie consent | **Klaro** (open source, GDPR-compliant) |

### Workflow pracy

```
1. Pobieranie danych    → Skrypty R (web scraping Stooq, Biznesradar)
2. Przetwarzanie        → Obliczanie wskaźników (SMA, indeksy, sentyment)
3. Zapis danych         → Pliki .RDS w katalogu data/
4. Rendering strony     → quarto render (lokalnie)
5. Commit + Push        → git add . && git commit && git push
6. Deploy               → Netlify automatycznie buduje z _site/
```

**Ważne:** Strona jest renderowana **lokalnie** (nie na serwerze Netlify). Netlify pobiera gotowy folder `_site/` z GitHub.

---

## 3. Struktura katalogów projektu

```
domenarynku/
├── _quarto.yml                  # Główna konfiguracja Quarto
├── _language-pl.yml             # Tłumaczenia interfejsu na polski
├── domenarynku.Rproj            # Plik projektu RStudio
├── index.qmd                    # Strona główna
├── about.qmd                    # Strona "O nas"
├── styles.css                   # Style CSS (custom design)
├── klaro-config.js              # Konfiguracja cookie consent
├── .gitignore                   # Kontrola wersjonowania
│
├── sentyment-rynku/             # Sekcja: Sentyment rynku
│   ├── polska.qmd               # Sentyment PL (FW20)
│   └── usa.qmd                  # Sentyment USA (S&P500)
│
├── indeksy/                     # Sekcja: Indeksy autorskie
│   ├── indeks-trendow-gpw.qmd   # Indeks trendów (market breadth)
│   └── indeks-cenowy-top100.qmd # Indeks cenowy równoważony
│
├── spolki-gpw.qmd               # Strona zbiorcza spółek GPW
│
├── posts/                       # Blog — posty analityczne
│   ├── _metadata.yml             # Domyślne ustawienia postów
│   └── YYYY-MM-DD-tytul/        # Posty w folderach z datą
│       └── index.qmd
│
├── data/                        # Dane przetworzone (.RDS)
│   ├── index_trend.RDS           # Indeks trendów + WIG/WIG20
│   ├── index_price.RDS           # Indeks cenowy równoważony
│   ├── index_unweighted.RDS      # Indeks niezważony
│   ├── sentiment.RDS             # Sentyment PL
│   ├── sentimentEN.RDS           # Sentyment USA
│   ├── prices100.RDS             # Notowania historyczne top 100
│   ├── tickers_100_selected.RDS  # Lista 100 tickerów w składzie indeksów
│   ├── stock_list.RDS            # Pełna lista spółek GPW
│   ├── gpw_companies.RDS         # Metadane spółek
│   ├── www_data2.RDS             # Dane ze scrapingu stron spółek
│   ├── table_hrefs.RDS           # Linki do stron spółek
│   └── branze_podbranze.csv      # Klasyfikacja sektorowa
│
├── R/                           # Skrypty R (PRYWATNE — nie pushuj!)
│   ├── calc_trend_index.R        # Obliczanie indeksu trendów
│   ├── calc_price_index.R        # Obliczanie indeksu cenowego
│   ├── data_sentiment_prep.R     # Przetwarzanie sentymentu PL
│   ├── data_sentiment_prepEN.R   # Przetwarzanie sentymentu USA
│   ├── get_prices2.R             # Pobieranie notowań ze Stooq
│   ├── get_statica.R             # Pobieranie danych statycznych FW20
│   ├── read_companies_websites.R # Scraping stron spółek
│   └── collect_company_data.R    # Zbieranie metadanych spółek
│
├── mod/                         # Moduły box (PRYWATNE)
│   └── gpw.R                    # Moduł funkcji pomocniczych GPW
│
├── images/                      # Grafiki
│   └── domenarynku-logo-v2.svg  # Logo serwisu (białe SVG)
│
├── _site/                       # Wygenerowana strona (do deployu)
├── _freeze/                     # Cache Quarto (freeze: auto)
└── .quarto/                     # Pliki tymczasowe Quarto
```

---

## 4. Kluczowe pliki konfiguracyjne

### _quarto.yml — konfiguracja Quarto

```yaml
project:
  type: website

execute:
  freeze: auto                    # Cache — renderuje ponownie tylko zmienione pliki

website:
  title: "DomenaRynku.pl"
  site-url: "https://domenarynku.pl"
  favicon: images/domenarynku-logo-v2.svg
  open-graph: true                # Karty społecznościowe (Facebook, LinkedIn)
  twitter-card: true              # Karty Twittera
  navbar:
    logo: images/domenarynku-logo-v2.svg
    title: false
    left:                         # Menu nawigacyjne
      - href: index.qmd / text: Strona główna
      - text: "Sentyment rynku"   # Dropdown
        menu:
          - href: sentyment-rynku/polska.qmd / text: Polska
          - href: sentyment-rynku/usa.qmd   / text: USA
      - text: "Indeksy"           # Dropdown
        menu:
          - href: indeksy/indeks-trendow-gpw.qmd / text: Indeks trendów GPW
          - href: indeksy/indeks-cenowy-top100.qmd / text: Indeks cenowy top 100 GPW
      - href: spolki-gpw.qmd / text: Spółki GPW
    right:
      - href: about.qmd / text: O nas

lang: pl

format:
  html:
    theme: cosmo
    css: styles.css
    toc: true
    toc-depth: 3
    language: _language-pl.yml
    canonical-url: true           # Automatyczne URL-e kanoniczne
    header-includes: |            # Tu jest GTM, Klaro, Consent Mode v2
      (...)
    include-before-body-text: |   # Tu jest GTM noscript
      (...)
```

**Ważne elementy `header-includes` (kolejność ma znaczenie!):**

1. Google Consent Mode v2 — domyślnie `denied` na wszystko (GDPR)
2. Klaro CSS
3. Klaro Config (`klaro-config.js`)
4. Klaro JS
5. Google Tag Manager (`GTM-NXN55TCK`)
6. Meta tagi: `author`, `robots`, `googlebot`

### .gitignore — co NIE trafia na GitHub

```gitignore
# Wrażliwe skrypty scrapujące
R/
scripts/
mod/

# Dane surowe
data/

# Quarto cache
_freeze/
.quarto/

# System R
.Rproj.user
.Rhistory
.RData

# System OS
.DS_Store
Thumbs.db
```

**Uwaga:** Folder `_site/` NIE jest w .gitignore — musi trafić na GitHub, bo Netlify z niego serwuje stronę.

---

## 5. Metodologia wskaźników

### 5.1 Indeks Trendów GPW (Market Breadth)

**Plik obliczeniowy:** `R/calc_trend_index.R`  
**Dane wyjściowe:** `data/index_trend.RDS`  
**Strona:** `indeksy/indeks-trendow-gpw.qmd`

**Co mierzy:** Procent spółek z top 100 GPW, które znajdują się w trendzie wzrostowym.

**Algorytm:**

```r
# Dla każdej spółki:
sma_short <- SMA(price, n = 2)    # Krótkoterminowa (celowo 2 — przetestowane)
sma_long  <- SMA(price, n = 200)  # Długoterminowa

# Spółka jest w trendzie wzrostowym gdy:
is_uptrend <- lag(sma_short, 1) > lag(sma_long, 1)  # lag unika look-ahead bias

# Indeks = suma spółek w trendzie / liczba dostępnych spółek × 100
index_trend_perc <- sum(is_uptrend) / available_companies * 100
```

**Filtrowanie:** Spółki muszą mieć minimum 250 dni historii notowań.

**Interpretacja:**

- > 70% — silny rynek byka (broad rally)
- 50–70% — umiarkowana hossa
- 30–50% — neutralny/mieszany
- < 30% — rynek niedźwiedzia

**Analiza dywergencji (kluczowa wartość):**

- WIG rośnie + indeks trendów spada → ostrzeżenie przed korektą (negatywna dywergencja)
- WIG spada + indeks trendów rośnie → potencjalne dno rynku (pozytywna dywergencja)

Korelacja z WIG/WIG20 wynosi 0.25–0.28 w normalnych warunkach, ale rośnie do 0.66–0.73 podczas silnych trendów.

### 5.2 Indeks Cenowy Równoważony (Equal-Weighted Price Index)

**Plik obliczeniowy:** `R/calc_price_index.R`  
**Dane wyjściowe:** `data/index_price.RDS`  
**Strona:** `indeksy/indeks-cenowy-top100.qmd`

**Inspiracja:** Zweig Unweighted Price Index (ZUPI) z "Winning on Wall Street".

**Algorytm (po refaktoringu na logarytmiczne zwroty):**

```r
# 1. Logarytmiczne zwroty dla każdej spółki
log_returns <- diff(log(prices))

# 2. Średnia zwrotów (równe wagi — każda spółka = 1 udział)
avg_return <- rowMeans(log_returns, na.rm = TRUE)

# 3. Kumulatywny indeks
index <- exp(cumsum(avg_return)) * 100
```

**Dlaczego równe wagi:** WIG/WIG20 są ważone kapitalizacją — kilka dużych spółek (PKO, PKN Orlen, KGHM) dominuje wartość indeksu. Indeks równoważony daje "demokratyczny" obraz rynku i lepiej wykrywa, czy wzrost jest szerokim trendem, czy jest napędzany przez kilka spółek.

### 5.3 Sentyment Rynku

**Pliki obliczeniowe:** `R/data_sentiment_prep.R` (PL), `R/data_sentiment_prepEN.R` (USA)  
**Dane wyjściowe:** `data/sentiment.RDS`, `data/sentimentEN.RDS`  
**Strony:** `sentyment-rynku/polska.qmd`, `sentyment-rynku/usa.qmd`

**Metodologia sentymentu polskiego:**

- Zbieranie nagłówków z głównych serwisów giełdowych/finansowych codziennie przed sesją GPW
- Klasyfikacja każdego nagłówka: +1 (pozytywny), 0 (neutralny), -1 (negatywny)
- Suma dzienna → normalizacja do skali 0–100
- Dane zbierane od września 2023

**Sentyment USA:** Analogicznie, na bazie danych z rynku opcji S&P500 i VIX. Uwaga: dane mają przerwę — seria 1: 2023-09-17 do 2024-11-03, seria 2: od 2025-03-28. Na stronie wyświetlane są dwa osobne wykresy historyczne.

**Interpretacja:**

- > 80 — ekstremalna euforia (potencjalny szczyt)
- 50–80 — optymizm
- 20–50 — pesymizm
- < 20 — panika (potencjalne dno)

---

## 6. Pakiety R używane w projekcie

### Analiza danych i serie czasowe

| Pakiet | Zastosowanie |
|--------|-------------|
| `tidyverse` (dplyr, tidyr, purrr, stringr, ggplot2) | Przetwarzanie danych |
| `xts`, `zoo` | Serie czasowe, indeksowanie po datach |
| `quantmod` | Pobieranie danych giełdowych |
| `TTR` | Wskaźniki techniczne (SMA, EMA) |
| `PerformanceAnalytics` | Metryki performance |

### Web scraping

| Pakiet | Zastosowanie |
|--------|-------------|
| `rvest` | Parsowanie HTML |
| `httr` | Zapytania HTTP |
| `jsonlite` | Parsowanie JSON |

### Wizualizacja i prezentacja

| Pakiet | Zastosowanie |
|--------|-------------|
| `plotly` | Interaktywne wykresy (główna biblioteka) |
| `kableExtra` | Tabele HTML |

### Modularyzacja i narzędzia

| Pakiet | Zastosowanie |
|--------|-------------|
| `box` | System modułowy (`box::use(mod/gpw)`) |
| `purrr::possibly()` | Obsługa błędów przy scrapingu |

### Kluczowe komendy

```r
# Importowanie modułu GPW:
box::use(mod/gpw)

# Pobieranie danych z stooq:
gpw$stooq_dw(ticker)

# Rendering strony:
quarto::quarto_render()              # Cały projekt
quarto::quarto_render("plik.qmd")   # Jeden plik
quarto::quarto_preview()            # Podgląd na żywo

# Obsługa błędów przy scrapingu:
safe_read <- purrr::possibly(rvest::read_html, otherwise = NA)
```

---

## 7. Komendy — codzienna obsługa

### Aktualizacja danych (przed sesją GPW)

```r
# 1. Pobierz nowe notowania
source("R/get_prices2.R")

# 2. Przelicz indeksy
source("R/calc_trend_index.R")
source("R/calc_price_index.R")

# 3. Aktualizuj sentyment
source("R/data_sentiment_prep.R")
source("R/data_sentiment_prepEN.R")
```

### Rendering i deploy

```bash
# W RStudio lub terminalu:
quarto render

# Lub w konsoli R:
quarto::quarto_render()

# Deploy:
git add .
git commit -m "Aktualizacja danych YYYY-MM-DD"
git push
# → Netlify automatycznie wdroży nową wersję
```

### Podgląd lokalny

```r
quarto::quarto_preview()
# Otwiera stronę na localhost z hot-reload
```

### Renderowanie pojedynczego pliku

```r
quarto::quarto_render("indeksy/indeks-trendow-gpw.qmd")
```

**Uwaga:** Po zmianach w `_quarto.yml` (menu, style, meta tagi) renderuj cały projekt, nie pojedyncze pliki.

---

## 8. Konfiguracja Netlify

### Parametry projektu

| Ustawienie | Wartość |
|-----------|---------|
| Build command | _(puste — build lokalny)_ |
| Publish directory | `_site` |
| Branch | `main` |
| Domena | `domenarynku.pl` |

### Jak działa deployment

1. Renderujesz stronę **lokalnie** komendą `quarto render`
2. Quarto generuje folder `_site/` z plikami HTML
3. Commitujesz `_site/` do Git i pushujesz na GitHub
4. Netlify wykrywa push i automatycznie publikuje zawartość `_site/`
5. Strona jest dostępna pod domenarynku.pl

### Domeny w Netlify

- `domenarynku.netlify.app` — subdomena Netlify
- `domenarynku.pl` — domena główna (primary domain, Netlify DNS)
- `www.domenarynku.pl` — automatyczne przekierowanie do domeny głównej
- HTTPS — automatyczny certyfikat Let's Encrypt

### netlify.toml (jeśli istnieje)

```toml
[build]
  publish = "_site"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[build.processing.css]
  bundle = true
  minify = true

[build.processing.js]
  bundle = true
  minify = true

[build.processing.images]
  compress = true
```

---

## 9. SEO i tracking

### Google Tag Manager

- ID kontenera: `GTM-NXN55TCK`
- Skrypt GTM w `<head>` (header-includes w _quarto.yml)
- Noscript GTM w `<body>` (include-before-body-text w _quarto.yml)

### Google Analytics 4

- Konfiguracja przez GTM (nie bezpośrednio)
- Tag Google w GTM z identyfikatorem GA4

### Consent Mode v2 (GDPR)

Przed załadowaniem GTM, `_quarto.yml` ustawia domyślne zgody na `denied`:

```javascript
gtag('consent', 'default', {
  'ad_storage': 'denied',
  'ad_user_data': 'denied',
  'ad_personalization': 'denied',
  'analytics_storage': 'denied',
  'wait_for_update': 500
});
```

### Klaro Cookie Consent

**Plik:** `klaro-config.js`

Kategorie cookies:

| Kategoria | Opis | Domyślnie |
|-----------|------|-----------|
| Niezbędne | Wymagane do działania strony | Zawsze ON |
| Analytics | Google Analytics | OFF (wymaga zgody) |
| Marketing | Google Ads (przygotowane na przyszłość) | OFF |
| Personalizacja | Preferencje użytkownika | OFF |
| Social Media | Przyciski udostępniania | OFF |

Klaro jest ostylowane w `styles.css` z kolorystyką strony (białe tło, niebieskie przyciski, gradient).

### SEO na poziomie stron .qmd

Każdy plik .qmd powinien mieć w nagłówku YAML:

```yaml
---
title: "Tytuł widoczny na stronie"
pagetitle: "Tytuł SEO | DomenaRynku.pl"
date: "2024-11-21"
date-modified: last-modified
format:
  html:
    header-includes: |
      <meta name="description" content="Opis 150-160 znaków dla Google">
      <meta name="keywords" content="słowa, kluczowe, rozdzielone, przecinkami">
---
```

### Inne elementy SEO

- `canonical-url: true` w _quarto.yml — automatyczne kanoniczne URL
- `open-graph: true` — karty Facebook/LinkedIn
- `twitter-card: true` — karty Twitter
- `sitemap.xml` — generowany automatycznie przez Quarto
- Meta `robots: index, follow` — globalnie w header-includes
- Responsywny design (mobile-friendly)

---

## 10. Design i branding

### Kolorystyka (zmienne CSS w styles.css)

```css
--primary-blue: #1e3a8a;     /* Główny niebieski (ciemny) */
--accent-blue: #3b82f6;      /* Akcent (jasny niebieski) */
--light-blue: #93c5fd;       /* Hover states */
--gray-text: #64748b;        /* Tekst pomocniczy */
--dark-text: #1e293b;        /* Tekst główny */
```

### Kluczowe elementy wizualne

- Navbar: gradient `linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)`
- Logo: białe SVG na ciemnym tle nawigacji
- Karty: cień + hover effect (`transform: translateY(-4px)`)
- Posty: `border-left: 4px solid blue` na kartach
- Font: Segoe UI (system fonts)
- Motyw Quarto: cosmo

---

## 11. Konwencje i zasady

### Nazewnictwo plików

| Typ | Konwencja | Przykład |
|-----|-----------|---------|
| Strony Quarto | kebab-case | `indeks-trendow-gpw.qmd` |
| Posty blogowe | `YYYY-MM-DD-tytul/index.qmd` | `2024-11-21-analiza-trendow/index.qmd` |
| Skrypty R | snake_case | `calc_trend_index.R` |
| Dane | snake_case | `index_trend.RDS` |

### Język w analizach

Zawsze używaj neutralnych sformułowań:

- ✅ "Dane sugerują...", "Można rozważyć...", "Warto zwrócić uwagę na..."
- ❌ "Kup teraz!", "To jest świetna okazja!", "Gwarantowany zysk"

Każda strona analityczna powinna kończyć się callout-em z informacją prawną:

```
::: {.callout-important}
## Informacja prawna
Materiały publikowane na tej stronie mają charakter wyłącznie informacyjny
i edukacyjny. Nie stanowią porady inwestycyjnej, rekomendacji, ani oferty
kupna lub sprzedaży instrumentów finansowych.
:::
```

### Struktura postów blogowych

```
1. Lead — jedno zdanie podsumowujące
2. Kluczowe statystyki — liczby, zmiany, zakresy
3. Wykres interaktywny (plotly)
4. Analiza opisowa
5. Implikacje / co monitorować
6. Disclaimer prawny
```

---

## 12. Znane problemy i troubleshooting

### Problem: Quarto renderuje wszystkie pliki mimo `freeze: auto`

**Przyczyna:** `freeze` działa tylko dla plików z kodem R. Pliki bez bloków kodu R zawsze się re-renderują.

**Rozwiązanie:** To normalne zachowanie. Dla plików z kodem R, `_freeze/` przechowuje cache wyników.

### Problem: Timeout przy scrapingu stron spółek

**Przyczyna:** Niektóre strony WWW nie odpowiadają lub blokują scraping.

**Rozwiązanie:** Używaj `purrr::possibly()` z prawidłową składnią:

```r
safe_read <- possibly(read_html, otherwise = NA)
# NIE: possibly(~read_html(.x), otherwise = NA)
```

### Problem: Google Analytics nie widzi instalacji

**Przyczyna:** Klaro blokuje cookies analityczne domyślnie (GDPR). GA4 działa dopiero po akceptacji cookies przez użytkownika.

**Weryfikacja:** Otwórz stronę, zaakceptuj cookies analityczne w banerze Klaro, sprawdź w GA4 → Realtime.

### Problem: Nieczytelnyna czcionka w banerze Klaro

**Przyczyna:** Konflikt stylów Klaro z motywem strony.

**Rozwiązanie:** Agresywne nadpisanie w `styles.css` z `!important` na selektorach `.klaro .cookie-notice *`.

### Problem: Pliki wrażliwe widoczne na GitHub

**Przyczyna:** Pliki zostały dodane do Git PRZED utworzeniem .gitignore.

**Rozwiązanie:**

```bash
git rm -r --cached R/ mod/ scripts/ data/
git commit -m "Usuń wrażliwe pliki z trackingu"
git push
```

### Problem: Reticulate/Python procesy blokują render

**Przyczyna:** Python processes spawned by reticulate hang indefinitely.

**Rozwiązanie:** Unikaj `reticulate` w plikach .qmd. Jeśli konieczne, dodaj timeout.

---

## 13. Źródła danych

| Źródło | Dane | Częstotliwość |
|--------|------|---------------|
| Stooq (stooq.pl) | Notowania historyczne OHLC, wolumen | Codziennie |
| Biznesradar (biznesradar.pl) | Profile spółek, sektory, opisy | Jednorazowo / ad hoc |
| Google Finance | Dodatkowe dane o spółkach | Ad hoc |
| Serwisy finansowe PL | Nagłówki do analizy sentymentu | Codziennie |

**Funkcja pobierania notowań:** `gpw$stooq_dw(ticker)` w module `mod/gpw.R`.

---

## 14. Rozwój i plany

### W toku

- Kompletowanie profili 100 spółek GPW (część opisów gotowa, reszta do uzupełnienia)
- Regularne posty blogowe z analizami sesji FW20
- Rozbudowa szablonów postów (tygodniowe, miesięczne, kwartalne review)

### Planowane

- USA market sentiment — rozszerzenie o dodatkowe źródła
- Mapa cieplna sektorów GPW
- Interaktywna tabela spółek z filtrami
- Podstrony indywidualne dla każdej spółki (`/spolki-gpw/pko/`, `/spolki-gpw/kghm/` itd.)
- Google Ads — infrastruktura cookie consent jest już gotowa

---

## 15. Kontakty i narzędzia

- **GitHub repo:** (nazwa repozytorium: domenarynku)
- **Netlify panel:** app.netlify.com → projekt domenarynku
- **Google Tag Manager:** tagmanager.google.com → kontener GTM-NXN55TCK
- **Google Analytics:** analytics.google.com → property domenarynku.pl
- **Google Search Console:** search.google.com/search-console → domenarynku.pl

---

*Dokument wygenerowany na podstawie historii pracy nad projektem (listopad 2024 – luty 2026).*
