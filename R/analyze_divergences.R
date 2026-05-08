# =============================================================================
# Analiza dywergencji między indeksem trendów a WIG/WIG20
# =============================================================================

library(tidyverse)
library(xts)
library(zoo)
library(lubridate)

# Wczytaj dane
all_data <- readRDS("data/index_trend.RDS")

# =============================================================================
# 1. PRZYGOTOWANIE DANYCH
# =============================================================================

# Konwertuj xts do data frame dla ggplot
df <- data.frame(
  date = index(all_data),
  index_trend = as.numeric(all_data$index_trend_perc),
  wig20 = as.numeric(all_data$W20),
  wig = as.numeric(all_data$WIG)
)

# Oblicz zmiany (returns)
df <- df %>%
  mutate(
    index_change = c(NA, diff(index_trend)),
    wig_change = c(NA, diff(wig) / lag(wig) * 100),
    wig20_change = c(NA, diff(wig20) / lag(wig20) * 100)
  )

# =============================================================================
# 2. IDENTYFIKACJA DYWERGENCJI
# =============================================================================

df <- df %>%
  mutate(
    # Pozytywna dywergencja: index rośnie, WIG spada (potencjalnie bullish)
    pos_div_wig = (index_change > 0) & (wig_change < 0),
    
    # Negatywna dywergencja: index spada, WIG rośnie (potencjalnie bearish)
    neg_div_wig = (index_change < 0) & (wig_change > 0),
    
    # To samo dla WIG20
    pos_div_wig20 = (index_change > 0) & (wig20_change < 0),
    neg_div_wig20 = (index_change < 0) & (wig20_change > 0),
    
    # Kategoria dywergencji (do kolorowania)
    divergence = case_when(
      pos_div_wig ~ "Pozytywna (Index ↗, WIG ↘)",
      neg_div_wig ~ "Negatywna (Index ↘, WIG ↗)",
      TRUE ~ "Brak dywergencji"
    )
  )

# Zamień NA na FALSE
df <- df %>%
  mutate(across(c(pos_div_wig, neg_div_wig, pos_div_wig20, neg_div_wig20), 
                ~replace_na(., FALSE)))

# =============================================================================
# 3. STATYSTYKI
# =============================================================================

cat("\n=== STATYSTYKI DYWERGENCJI ===\n\n")

cat("Cały okres:\n")
cat("  Pozytywne dywergencje (Index ↗, WIG ↘):", sum(df$pos_div_wig), "\n")
cat("  Negatywne dywergencje (Index ↘, WIG ↗):", sum(df$neg_div_wig), "\n")
cat("  Razem dni z dywergencją:", sum(df$pos_div_wig | df$neg_div_wig), "\n")
cat("  Procent dni z dywergencją:", 
    round(sum(df$pos_div_wig | df$neg_div_wig) / nrow(df) * 100, 1), "%\n\n")

# Tylko rok 2025
df_2025 <- df %>% filter(year(date) == 2025)
cat("Rok 2025:\n")
cat("  Pozytywne dywergencje:", sum(df_2025$pos_div_wig, na.rm = TRUE), "\n")
cat("  Negatywne dywergencje:", sum(df_2025$neg_div_wig, na.rm = TRUE), "\n\n")

# =============================================================================
# 4. WYKRES GŁÓWNY - WIG Z ZAZNACZONYMI DYWERGENCJAMI
# =============================================================================

p1 <- ggplot(df, aes(x = date, y = wig)) +
  geom_line(color = "black", linewidth = 0.5) +
  
  # Zaznacz dywergencje jako punkty
  geom_point(data = df %>% filter(pos_div_wig), 
             aes(y = wig), color = "green", size = 2, alpha = 0.7) +
  geom_point(data = df %>% filter(neg_div_wig), 
             aes(y = wig), color = "red", size = 2, alpha = 0.7) +
  
  labs(
    title = "WIG z zaznaczonymi dywergencjami",
    subtitle = paste0("Zielony = Index ↗ & WIG ↘ (", sum(df$pos_div_wig), " dni) | ",
                     "Czerwony = Index ↘ & WIG ↗ (", sum(df$neg_div_wig), " dni)"),
    x = NULL,
    y = "WIG"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray40")
  )

print(p1)

# =============================================================================
# 5. WYKRES - SCATTER PLOT: Index vs WIG zmiany
# =============================================================================

p2 <- ggplot(df %>% filter(!is.na(index_change) & !is.na(wig_change)), 
             aes(x = index_change, y = wig_change)) +
  geom_point(aes(color = divergence), alpha = 0.6, size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c(
      "Pozytywna (Index ↗, WIG ↘)" = "green",
      "Negatywna (Index ↘, WIG ↗)" = "red",
      "Brak dywergencji" = "gray70"
    )
  ) +
  labs(
    title = "Scatter plot: Zmiana Index vs Zmiana WIG",
    x = "Zmiana Index Trendów (pkt %)",
    y = "Zmiana WIG (%)",
    color = "Typ punktu"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

print(p2)

# =============================================================================
# 6. WYKRES - ROLLING CORRELATION (60 dni)
# =============================================================================

# Oblicz ruchomą korelację
df <- df %>%
  arrange(date) %>%
  mutate(
    rolling_cor_60 = zoo::rollapply(
      cbind(index_trend, wig), 
      width = 60, 
      FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
      by.column = FALSE,
      align = "right",
      fill = NA
    )
  )

p3 <- ggplot(df, aes(x = date, y = rolling_cor_60)) +
  geom_line(color = "#3b82f6", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_hline(yintercept = c(-0.5, 0.5), linetype = "dotted", color = "gray70") +
  labs(
    title = "60-dniowa ruchoma korelacja: Index Trendów vs WIG",
    subtitle = "Niska korelacja może sygnalizować zmiany trendu",
    x = NULL,
    y = "Korelacja"
  ) +
  ylim(-1, 1) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray40")
  )

print(p3)

# =============================================================================
# 7. WYKRES - TRY SERIE NA JEDNYM (normalized)
# =============================================================================

# Normalizuj do 0-100 dla porównywalności
df_norm <- df %>%
  mutate(
    index_norm = (index_trend - min(index_trend, na.rm = TRUE)) / 
                 (max(index_trend, na.rm = TRUE) - min(index_trend, na.rm = TRUE)) * 100,
    wig_norm = (wig - min(wig, na.rm = TRUE)) / 
               (max(wig, na.rm = TRUE) - min(wig, na.rm = TRUE)) * 100,
    wig20_norm = (wig20 - min(wig20, na.rm = TRUE)) / 
                 (max(wig20, na.rm = TRUE) - min(wig20, na.rm = TRUE)) * 100
  )

# Przekształć do long format
df_long <- df_norm %>%
  select(date, index_norm, wig_norm, wig20_norm) %>%
  pivot_longer(cols = c(index_norm, wig_norm, wig20_norm),
               names_to = "series",
               values_to = "value") %>%
  mutate(
    series = recode(series,
      "index_norm" = "Index Trendów",
      "wig_norm" = "WIG",
      "wig20_norm" = "WIG20"
    )
  )

p4 <- ggplot(df_long, aes(x = date, y = value, color = series)) +
  geom_line(linewidth = 0.8, alpha = 0.8) +
  scale_color_manual(
    values = c("Index Trendów" = "#3b82f6", "WIG" = "#10b981", "WIG20" = "#f59e0b")
  ) +
  labs(
    title = "Porównanie znormalizowanych serii (0-100)",
    x = NULL,
    y = "Wartość znormalizowana",
    color = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

print(p4)

# =============================================================================
# 8. EKSPORT DANYCH Z DYWERGENCJAMI (opcjonalnie)
# =============================================================================

# Zapisz dni z dywergencjami do CSV (jeśli chcesz)
# df %>%
#   filter(pos_div_wig | neg_div_wig) %>%
#   select(date, index_trend, wig, index_change, wig_change, divergence) %>%
#   write.csv("data/divergences.csv", row.names = FALSE)

cat("\n=== Analiza zakończona ===\n")
cat("Wygenerowano 4 wykresy:\n")
cat("1. WIG z zaznaczonymi dywergencjami\n")
cat("2. Scatter plot Index vs WIG\n")
cat("3. Rolling correlation (60 dni)\n")
cat("4. Porównanie znormalizowanych serii\n\n")

