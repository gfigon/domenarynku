# Plan: Szablon profilu spółki - Lubawa (LBW)

## Cel

Stworzyć wzorcowy plik QMD dla profilu spółki GPW na przykładzie Lubawa (LBW).

## Wymagania sekcji "O spółce"

Sekcja ma zawierać wyłącznie 4 elementy (bez danych często zmieniających się):

1. **Czym spółka się zajmuje** - krótki opis działalności
2. **Jakie zasoby/surowce wykorzystuje** - surowce, zasoby, infrastruktura
3. **Co sprzedaje** - produkty i usługi
4. **Wizja/cel/misja/perspektywy rozwoju** - do czego spółka dąży

## Plik do modyfikacji

`spolki/lbw.qmd`

## Podejście

1. Przeczytać obecny plik lbw.qmd
2. Zachować:
   - Nagłówek YAML
   - Sekcję R (dane notowań)
   - Header (company-header)
   - Value boxes (cena, zmiana d/d, zmiana y/y)
   - Sekcję "Notowania" (wykres)
   - Stopkę prawną

3. Zastąpić sekcje "Biznes" i "Strategia" jedną sekcją "O spółce" zawierającą wyłącznie 4 elementy wymienione powyżej

## Weryfikacja

Po zmianach:
1. `quarto render spolki/lbw.qmd` - test renderowania
2. Sprawdzenie czy wyświetla się poprawnie
