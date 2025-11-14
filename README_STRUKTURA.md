# DomenaRynku.pl - Struktura projektu

## 📁 Struktura katalogów

```
/
├── data/                          # Dane projektu
│   ├── raw/                       # Surowe dane z API/źródeł
│   └── processed/                 # Przetworzone dane (.RDS)
│       └── indeks_trendow.RDS    # Dane dla indeksu trendów
│
├── mod/                           # Moduły box
│   └── gpw.R                     # Moduł do pracy z danymi GPW
│
├── R/                             # Skrypty pomocnicze R
│   └── funkcje_pomocnicze.R      # Funkcje używane w projekcie
│
├── scripts/                       # Skrypty aktualizacji
│   └── update_indeks_trendow.R   # Skrypt aktualizujący dane indeksu
│
├── indeksy/                       # Strony z indeksami
│   ├── indeks-trendow-gpw.qmd    # Strona indeksu trendów
│   └── indeks-cenowy-top100.qmd  # Strona indeksu cenowego
│
├── sentyment-gieldowy/            # Strony sentymentu
│   ├── polska.qmd
│   └── swiat.qmd
│
└── images/                        # Grafiki i logo
```

## 🔄 Workflow

### 1. Aktualizacja danych (wykonywane poza Quarto)

```r
# Uruchom skrypt aktualizacji
source("scripts/update_indeks_trendow.R")

# Lub bezpośrednio z box
box::use(mod/gpw)
# ... pobierz dane
saveRDS(dane, "data/processed/indeks_trendow.RDS")
```

### 2. Renderowanie strony

```r
# Renderuj pojedynczą stronę
quarto::quarto_render("indeksy/indeks-trendow-gpw.qmd")

# Lub całą stronę
quarto::quarto_render()
```

## 📊 Użycie w .qmd

W pliku `.qmd` zaciągasz dane:

```r
# Wczytaj dane
dane_indeksu <- readRDS("../data/processed/indeks_trendow.RDS")

# Oblicz indeks
indeks <- oblicz_indeks_trendow(dane_indeksu)

# Wyświetl wykres
plot_indeks(indeks)
```

## 🔧 Pakiety wymagane

- `dplyr` - przetwarzanie danych
- `ggplot2` - wykresy
- `box` - moduły
- `lubridate` - daty
- `knitr` - tabele

