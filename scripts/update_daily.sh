#!/bin/bash

# Ustawienie katalogu roboczego na root projektu
cd "$(dirname "$0")/.." || exit

# Logowanie startu
echo "Starting daily update: $(date)"

# 1. Pobieranie danych
echo "Fetching new prices..."
Rscript R/get_prices2.R

# 2. Przeliczanie indeksów
echo "Calculating Price Index..."
Rscript R/calc_price_index.R

echo "Calculating Trend Index..."
Rscript R/calc_trend_index.R

# 3. Renderowanie
# Wymuszenie aktualizacji stron spółek (obejście freeze: auto)
echo "Touching company pages to force re-render..."
touch spolki/*.qmd

echo "Rendering Company pages..."
quarto render spolki/

echo "Rendering Index pages..."
quarto render indeksy/

echo "Rendering Full Site..."
quarto render

# 4. Git & Deploy
echo "Pushing changes to Git..."
git add .
git commit -m "Auto-update: $(date +'%Y-%m-%d')"
git push

echo "Daily update finished: $(date)"
