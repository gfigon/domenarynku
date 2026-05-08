suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})
options(box.path = getwd())
box::use(R / mod / gpw)

OUTPUT      <- "data/prices100.RDS"
TMP_OUTPUT  <- "data/prices100.RDS.tmp"
MIN_TICKERS <- 80     # below this we keep the previous file
LOOKBACK    <- 30     # days for filter_na

tickers_100 <- readRDS("data/tickers_100_selected.RDS")
cat("Input ticker list:", length(tickers_100), "tickers\n")

price_data <- gpw$get_stooq_data(tickers_100)

# Drop tickers with no recent price activity. The old filter (sum of last 6
# values > 0) was too aggressive — a one-week trading halt removed the ticker
# entirely. Keep any ticker with at least one non-NA value in the last 30
# trading days.
recent_active <- function(x) any(!is.na(tail(x, LOOKBACK)))
tick_filter   <- map_lgl(price_data[, -1], recent_active)
price_data    <- price_data[, c(TRUE, tick_filter)]

n_kept <- ncol(price_data) - 1L
cat(sprintf("After filter_na: %d tickers retained (had %d non-NA in last %d days)\n",
            n_kept, n_kept, LOOKBACK))

# Atomic save: write to .tmp first, validate, then rename. If validation
# fails, the existing prices100.RDS stays untouched. This is the fix for the
# 2026-05-05 incident where a failed fetch silently overwrote the good file
# with NULL.
if (n_kept < MIN_TICKERS) {
  stop(sprintf(
    "Refusing to overwrite %s: only %d tickers retained (minimum %d). Existing file preserved.",
    OUTPUT, n_kept, MIN_TICKERS
  ))
}

saveRDS(price_data, TMP_OUTPUT)
file.rename(TMP_OUTPUT, OUTPUT)

cat(sprintf("Wrote %s with %d tickers (%d sessions).\n",
            OUTPUT, n_kept, nrow(price_data)))
