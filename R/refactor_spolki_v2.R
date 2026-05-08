# R/refactor_spolki_v2.R
# Skrypt refaktoryzujący profile spółek do formatu Markdown-Only Quarto Dashboard
# Zgodny z wytycznymi: brak Divów (:::{.card}), użycie nagłówków, poprawne listy.

library(stringr)
library(dplyr)
library(readr)

spolki_dir <- "spolki"

# Funkcja czyszcząca tekst (listy, disclaimery)
clean_text <- function(text) {
  if (is.na(text) || nchar(text) == 0) return("")
  
  # 1. Usuń stare disclaimery (Callouts lub Blockquotes)
  # Używamy gsub z perl=TRUE dla pewności obsługi (?s)
  # Usuwamy dowolny blok ::: {.callout...} ... :::
  text <- gsub("(?s)::: \\{\\.callout-.*?\\}.*?:::\\s*", "", text, perl = TRUE)
  # Usuwamy ewentualne niedomknięte otwarcia (jeśli regex nie złapał całości przez błąd struktury)
  text <- gsub("(?s)::: \\{\\.callout-.*?\\}\\s*", "", text, perl = TRUE)
  
  text <- str_remove_all(text, "(?s)> \\*\\*Informacja prawna\\*\\*.*")
  
  # 2. Napraw listy: Wymuś pustą linię przed listą (* lub -)
  text <- str_replace_all(text, "([^\\n])\\n(\\s*[*\\-]\\s+)", "\\1\n\n\\2")
  
  # 3. Usuń nadmiarowe białe znaki na końcach
  text <- str_trim(text)
  
  return(text)
}

# Funkcja wyciągająca sekcję z pliku
extract_section <- function(lines, keywords) {
  pattern <- paste0("^(#{3,4}|::: \\{\\.card title=\")\\s*(", paste(keywords, collapse="|"), ")")
  start_idx <- grep(pattern, lines, ignore.case = TRUE)[1]
  
  if(is.na(start_idx)) return("")
  if(start_idx == length(lines)) return("")
  
  rest_lines <- lines[(start_idx+1):length(lines)]
  
  started_with_div <- str_detect(lines[start_idx], "^:::")
  
  end_relative_idx <- grep("^(## |#{3,4}|::: \\{\\.card|::: \\{\\.tabset)", rest_lines)
  
  if(length(end_relative_idx) == 0) {
    section_lines <- rest_lines
  } else {
    first_end <- end_relative_idx[1]
    if(first_end == 1) return("") 
    section_lines <- rest_lines[1:(first_end-1)]
  }
  
  raw_text <- paste(section_lines, collapse = "\n")
  
  if (started_with_div) {
    raw_text <- str_remove(raw_text, "\\n:::\\s*$")
  }
  
  return(clean_text(raw_text))
}

# Główna funkcja przetwarzająca plik
process_file <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  content_full <- paste(lines, collapse = "\n")
  
  title_line <- lines[grep("^title:", lines)[1]]
  title_val <- str_remove(title_line, "^title: \"?") %>% str_remove("\"?$")
  
  ticker <- str_extract(title_val, "\\([A-Z0-9]+\\)") %>% str_remove_all("[\\(\\)]")
  if(is.na(ticker)) ticker <- "UNKNOWN"
  name_only <- str_remove(title_val, " \\([A-Z0-9]+\\)")
  
  branza <- "Inne"
  podbranza <- "Inne"
  cats_match <- str_match(content_full, "categories: \\[([^,]+), ([^\\]]+)\\]")
  if (!is.na(cats_match[1,1])) {
    branza <- str_trim(cats_match[1,2])
    podbranza <- str_trim(cats_match[1,3])
  } else {
    b_match <- str_match(content_full, "(?:branza=|category=)([\\w\\+\\- \\p{L}]+)")
    p_match <- str_match(content_full, "podbranza=([\\w\\+\\- \\p{L}]+)")
    if (!is.na(b_match[1,2])) branza <- str_replace_all(b_match[1,2], "\\+", " ")
    if (!is.na(p_match[1,2])) podbranza <- str_replace_all(p_match[1,2], "\\+", " ")
  }
  
  www <- str_extract(content_full, "\\[.*?\\]\\(https?://.*?\\)")
  if(is.na(www)) www <- "[Brak WWW](#)"
  siedziba_match <- str_match(content_full, "\\*\\*Siedziba:\\*\\* (.*?)  ")
  siedziba <- if(!is.na(siedziba_match[1,2])) str_trim(siedziba_match[1,2]) else "Polska"

  about <- extract_section(lines, c("O spółce"))
  
  if (about == "") {
    last_chunk <- max(c(0, grep("```", lines)))
    first_header <- min(c(length(lines)+1, grep("^(#{1,4}|:::)", lines)))
    headers_after <- grep("^(#{1,4}|:::)", lines)
    headers_after <- headers_after[headers_after > last_chunk]
    if(length(headers_after) > 0) first_header <- headers_after[1]
    
    if (first_header > last_chunk + 1) {
      potential_text <- paste(lines[(last_chunk+1):(first_header-1)], collapse="\n")
      if (nchar(str_trim(potential_text)) > 20) {
         about <- clean_text(potential_text)
      }
    }
  }
  
  business <- extract_section(lines, c("Biznes", "Produkty", "Usługi"))
  strategy <- extract_section(lines, c("Strategia", "Wizja", "Ekspansja"))
  
  link_branza <- sprintf("[%s](../spolki-gpw.html#category=%s)", branza, branza)
  link_podbranza <- sprintf("[%s](../spolki-gpw.html#category=%s)", podbranza, podbranza)
  
  disclaimer <- "> **Informacja prawna**\n> Materiały publikowane na tej stronie mają charakter wyłącznie informacyjny i edukacyjny. Nie stanowią porady inwestycyjnej."
  
  tabs_content <- ""
  tabs_content <- paste0(tabs_content, "#### Notowania\n\n")
  tabs_content <- paste0(tabs_content, sprintf('```{r}\nstock_xts <- xts(stock_data$price, order.by = as.Date(stock_data$date))\nsma200 <- SMA(stock_xts, n = 200)\nplot_ly(x = index(stock_xts), y = as.numeric(stock_xts), type = "scatter", mode = "lines", name = "Cena %s") %%>%%\n  add_lines(x = index(stock_xts), y = as.numeric(sma200), name = "SMA 200", line = list(color = "orange")) %%>%%\n  layout(xaxis = list(title = "", rangeslider = list(visible = TRUE)), yaxis = list(title = "Cena (PLN)"), legend = list(orientation = "h", x = 0.1, y = 1.1), margin = list(t = 50))\n```\n\n', ticker))
  
  if(nchar(about) > 0) tabs_content <- paste0(tabs_content, "#### O spółce\n\n", about, "\n\n")
  if(nchar(business) > 0) tabs_content <- paste0(tabs_content, "#### Biznes\n\n", business, "\n\n")
  if(nchar(strategy) > 0) tabs_content <- paste0(tabs_content, "#### Strategia\n\n", strategy, "\n\n")
  
  tabs_content <- paste0(tabs_content, "\n", disclaimer, "\n")

  final_qmd <- sprintf('---
title: "%s (%s)"
categories: [%s, %s]
format: 
  dashboard:
    orientation: columns
    nav-buttons:
      - icon: arrow-left
        href: ../spolki-gpw.html
        text: "Powrót"
      - icon: github
        href: "https://github.com/skutek/domenarynku"
---

```{r setup, include=FALSE}
library(tidyverse)
library(plotly)
library(xts)
library(TTR)

get_stock_data <- function(ticker) {
  path <- "../data/prices100.RDS"
  if(!file.exists(path)) return(NULL)
  prices_all <- readRDS(path)
  col_idx <- which(names(prices_all) == ticker)
  if(length(col_idx) == 0) return(NULL)
  df <- prices_all[, c(1, col_idx)]
  names(df) <- c("date", "price")
  df <- df %%>%% filter(!is.na(price))
  return(df)
}

stock_data <- get_stock_data("%s")
last_row <- tail(stock_data, 1)
last_price <- last_row$price
last_date <- last_row$date
prev_price <- tail(stock_data$price, 2)[1]
change_pct <- round((last_price - prev_price) / prev_price * 100, 2)
y_ago_idx <- nrow(stock_data) - 252
if(y_ago_idx > 0) {
  y_ago_price <- stock_data$price[y_ago_idx]
  change_yy <- round((last_price - y_ago_price) / y_ago_price * 100, 2)
} else {
  change_yy <- "N/A"
}
title_lp <- paste0("Cena (", last_date, ")")
```

## Row {height=8%%}

### Dane

<div style="font-size: 0.85em; display: flex; justify-content: space-around; align-items: center; padding: 5px;">
  <span>**Ticker:** %s</span>
  <span>**%s**</span>
  <span>**Siedziba:** %s</span>
  <span>**WWW:** %s</span>
  <span>**Branża:** %s</span>
  <span>**Podbranża:** %s</span>
</div>

## Row {height=92%%}

### Column {width=22%%}

```{r}
#| content: valuebox
#| title: !expr title_lp
list(icon = "currency-exchange", color = "primary", value = round(last_price, 2))
```

<style>
.value-box .value-box-value { font-size: 1.8em !important; }
.value-box .value-box-title { font-size: 0.8em !important; }
</style>

```{r}
#| content: valuebox
#| title: "Zmiana d/d"
list(icon = "graph-up", color = if(change_pct >= 0) "success" else "danger", value = paste0(change_pct, "%%"))
```

```{r}
#| content: valuebox
#| title: "Zmiana y/y"
list(icon = "calendar-check", color = if(is.numeric(change_yy) && change_yy >= 0) "success" else if(is.numeric(change_yy)) "danger" else "secondary", value = if(is.numeric(change_yy)) paste0(change_yy, "%%") else change_yy)
```

### Column {width=78%% .tabset}

%s
', 
  name_only, ticker, branza, podbranza,
  ticker,
  ticker, name_only, siedziba, www, link_branza, link_podbranza,
  tabs_content
  )
  
  writeLines(final_qmd, file_path)
  message(paste("Przetworzono:", file_path))
}

# Wykonanie
files <- list.files(spolki_dir, pattern = "\\.qmd$", full.names = TRUE)
for(f in files) {
  tryCatch({
    process_file(f)
  }, error = function(e) message(paste("Błąd:", f, e$message)))
}
