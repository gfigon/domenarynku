#!/usr/bin/env Rscript
# Make every spolki/<ticker>.qmd setup chunk and chart chunk safe against a
# missing/empty data/prices100.RDS or an absent ticker column.
#
# Idempotent — uses a sentinel comment `# stock_data guard v1` to detect
# already-migrated files. Re-running is a no-op.

suppressPackageStartupMessages(library(stringr))

# Resolve project root.
.this_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", args, value = TRUE)
  if (length(m)) sub("^--file=", "", m[1]) else NULL
}
.script_path <- .this_script()
if (!is.null(.script_path) && nzchar(.script_path)) {
  setwd(normalizePath(file.path(dirname(.script_path), "..")))
}

GUARD_MARKER <- "# stock_data guard v1"

# Replacement for the setup chunk math block. Sets safe defaults first, then
# only computes change_pct/change_yy/colors when the data is actually present.
SETUP_REPLACEMENT <- function(ticker) {
  paste0(
    'stock_data <- get_stock_data("', ticker, '")\n',
    GUARD_MARKER, '\n',
    'last_price <- NA_real_; last_date <- Sys.Date()\n',
    'change_pct <- NA_real_; change_yy <- "N/A"\n',
    'color_dd <- "secondary"; color_yy <- "secondary"; val_yy <- "N/A"\n',
    'if (!is.null(stock_data) && nrow(stock_data) >= 2) {\n',
    '  last_row <- tail(stock_data, 1)\n',
    '  last_price <- last_row$price\n',
    '  last_date <- last_row$date\n',
    '  prev_price <- tail(stock_data$price, 2)[1]\n',
    '  change_pct <- round((last_price - prev_price) / prev_price * 100, 2)\n',
    '  y_ago_idx <- nrow(stock_data) - 252\n',
    '  if (y_ago_idx > 0) {\n',
    '    y_ago_price <- stock_data$price[y_ago_idx]\n',
    '    change_yy <- round((last_price - y_ago_price) / y_ago_price * 100, 2)\n',
    '  }\n',
    '  color_dd <- if (change_pct >= 0) "success" else "danger"\n',
    '  color_yy <- if (is.numeric(change_yy) && change_yy >= 0) "success" else if (is.numeric(change_yy)) "danger" else "secondary"\n',
    '  val_yy   <- if (is.numeric(change_yy)) paste0(change_yy, "%") else change_yy\n',
    '}'
  )
}

# Wrap the chart chunk's R code in an if/else.
chart_wrap <- function(body) {
  paste0(
    'if (is.null(stock_data) || nrow(stock_data) < 2) {\n',
    '  cat("\\n*Brak aktualnych notowań dla tej spółki.*\\n")\n',
    '} else {\n',
    paste0("  ", strsplit(body, "\n", fixed = TRUE)[[1]], collapse = "\n"),
    '\n}'
  )
}

migrate_file <- function(p) {
  src <- readLines(p, warn = FALSE)
  if (any(str_detect(src, fixed(GUARD_MARKER)))) {
    return(FALSE)  # already migrated
  }

  new <- src

  # --- 1. Setup-chunk math: replace from `stock_data <- get_stock_data(...)`
  # through the `val_yy <- ...` line.
  start_re <- '^stock_data\\s*<-\\s*get_stock_data\\("([^"]+)"\\)\\s*$'
  end_re   <- '^val_yy\\s*<-\\s*if'

  start_idx <- str_which(new, start_re)
  if (length(start_idx) == 0L) return(FALSE)

  ticker <- str_match(new[start_idx[1]], start_re)[1, 2]
  end_idx <- str_which(new, end_re)
  end_idx <- end_idx[end_idx > start_idx[1]]
  if (length(end_idx) == 0L) return(FALSE)

  block_replacement <- strsplit(SETUP_REPLACEMENT(ticker), "\n", fixed = TRUE)[[1]]
  new <- c(
    new[seq_len(start_idx[1] - 1L)],
    block_replacement,
    new[(end_idx[1] + 1L):length(new)]
  )

  # --- 2. Chart-chunk wrap: locate `stock_xts <- xts(stock_data$price` and
  # capture from there to the next ``` chunk-close. Wrap in if/else.
  xts_re <- "^stock_xts\\s*<-\\s*xts\\(stock_data\\$price"
  chunk_close_re <- "^```\\s*$"

  xts_idx <- str_which(new, xts_re)
  if (length(xts_idx) > 0L) {
    closes <- str_which(new, chunk_close_re)
    closes <- closes[closes > xts_idx[1]]
    if (length(closes) > 0L) {
      body_lines <- new[xts_idx[1]:(closes[1] - 1L)]
      wrapped <- strsplit(chart_wrap(paste(body_lines, collapse = "\n")), "\n", fixed = TRUE)[[1]]
      new <- c(
        new[seq_len(xts_idx[1] - 1L)],
        wrapped,
        new[closes[1]:length(new)]
      )
    }
  }

  if (!identical(new, src)) {
    writeLines(new, p)
    return(TRUE)
  }
  FALSE
}

profiles <- list.files("spolki", pattern = "\\.qmd$",
                       recursive = FALSE, full.names = TRUE)
profiles <- profiles[basename(profiles) != "_metadata.yml"]

changed <- 0L
for (p in profiles) {
  if (migrate_file(p)) changed <- changed + 1L
}

cat(sprintf("Hardened setup+chart chunks in %d of %d company profiles.\n",
            changed, length(profiles)))
