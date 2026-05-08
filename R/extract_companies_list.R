library(tidyverse)

# Wczytaj tickery
tickers_100 <- readRDS("data/tickers_100_selected.RDS")

# Wczytaj tabelę ze spółkami
stock_list <- readRDS("data/stock_list.RDS")

# Połącz dane
companies_list <- tibble(ticker = tickers_100) %>%
  left_join(stock_list %>% select(ticker, name), by = "ticker") %>%
  mutate(
    # Usuń nawiasy z nazw
    name_clean = str_remove_all(name, "\\(|\\)"),
    # Dodaj kolumny, które wypełnimy później
    full_name = NA_character_,
    sector = NA_character_,
    description = NA_character_,
    website = NA_character_
  )

# Wyświetl
cat("=== 100 SPÓŁEK DO OPISANIA ===\n\n")
for(i in 1:nrow(companies_list)) {
  cat(sprintf("%3d. %s - %s\n", 
              i, 
              companies_list$ticker[i], 
              companies_list$name_clean[i]))
}

cat("\n\nLiczba spółek:", nrow(companies_list), "\n")

# Zapisz
companies_list %>% saveRDS("data/companies_profiles_template.RDS")
cat("\nZapisano do data/companies_profiles_template.RDS\n")

