box::use(
  httr[...],
  jsonlite[...],
  xts[...],
  zoo[...],
  rvest[...],
  dplyr[...],
  tibble = tibble[tibble],
  tidyr = tidyr[separate],
  purrr = purrr[map, slowly, rate_delay],
  readr = readr[read_csv],
  janitor = janitor[clean_names],
  sjmisc = sjmisc[rotate_df],
  stats = stats[na.omit],
  stringr = stringr[str_remove_all],
  readr = readr[parse_number]
)


# ---- stooq fetcher ----------------------------------------------------------
# Behavior contract:
# - Returns a 2-column tibble (Date, <ticker>) on success.
# - Throws a classified error on real failures (paywall, HTTP, malformed CSV)
#   so the caller can decide whether to retry, skip, or abort. Returning NULL
#   silently is the bug that destroyed prices100.RDS on 2026-05-05; do not
#   reintroduce it.
#
# Defenses against the paywall observed on 2026-05-07:
# - Real-browser User-Agent (the bare "Mozilla/5.0" string was being filtered).
# - Optional Cookie header from Sys.getenv("STOOQ_COOKIE") for cases where
#   the IP gets soft-banned and a logged-in session works around it.
# - Retry with exponential backoff (2 attempts after the first) for transient
#   network errors and 5xx.
# - Throttle is applied at the caller level via slowly(rate_delay(0.6)) so
#   100 tickers stay under stooq's anonymous-quota threshold.

.stooq_ua <- paste(
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
  "AppleWebKit/537.36 (KHTML, like Gecko)",
  "Chrome/124.0.0.0 Safari/537.36"
)

.stooq_paywall_re <- "^(Uzyskaj apikey|Get your apikey)"

.stooq_get <- function(url) {
  cookie <- Sys.getenv("STOOQ_COOKIE", unset = "")
  hdrs <- add_headers(
    `User-Agent` = .stooq_ua,
    Accept = "text/csv,text/plain,*/*",
    `Accept-Language` = "pl-PL,pl;q=0.9,en;q=0.8"
  )
  req_args <- list(url, hdrs, timeout(20))
  if (nzchar(cookie)) req_args <- c(req_args, list(set_cookies(PHPSESSID = cookie)))
  do.call(GET, req_args)
}

.stooq_csv <- function(url, attempts = 3) {
  last_err <- NULL
  for (i in seq_len(attempts)) {
    res <- tryCatch(.stooq_get(url), error = function(e) e)
    if (inherits(res, "error")) {
      last_err <- conditionMessage(res)
      Sys.sleep(min(2 ^ (i - 1), 8))
      next
    }
    sc <- status_code(res)
    body <- content(res, as = "text", encoding = "UTF-8")
    if (sc >= 500) {
      last_err <- paste0("HTTP ", sc)
      Sys.sleep(min(2 ^ (i - 1), 8))
      next
    }
    if (sc != 200) {
      stop(sprintf("stooq HTTP %d for %s", sc, url))
    }
    if (grepl(.stooq_paywall_re, body)) {
      stop(sprintf("stooq paywall for %s — IP throttled or apikey required", url))
    }
    if (!nzchar(body)) {
      last_err <- "empty body"
      Sys.sleep(min(2 ^ (i - 1), 8))
      next
    }
    return(read_csv(I(body), show_col_types = FALSE))
  }
  stop(sprintf("stooq fetch failed after %d attempts for %s: %s",
               attempts, url, last_err %||% "unknown"))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

stooq_dw <- function(symbol, close_only = TRUE) {
  full_link <- paste0("https://stooq.pl/q/d/l/?s=", symbol, "&i=d")

  my_data <- .stooq_csv(full_link)

  expected <- c("Data", "Otwarcie", "Najwyzszy", "Najnizszy", "Zamkniecie")
  if (nrow(my_data) == 0 || !all(expected %in% names(my_data))) {
    stop(sprintf(
      "stooq CSV for %s missing expected columns; got: %s",
      symbol, paste(names(my_data), collapse = ", ")
    ))
  }

  my_data <- my_data %>%
    dplyr::select(Data, Otwarcie, Najwyzszy, Najnizszy, Zamkniecie)
  colnames(my_data) <- c("Date", "Open", "High", "Low", "Close")

  if (nrow(my_data) > 0 && any(!is.na(my_data$Close))) {
    my_data <- na.locf(my_data, na.rm = FALSE)
  }

  if (close_only) {
    safe_col_name <- make.names(gsub("[^[:alnum:] ]", "", symbol))
    my_data <- my_data %>%
      dplyr::select(Date, Close) %>%
      dplyr::rename_with(~safe_col_name, .cols = Close)
  }
  my_data
}


# ---- local stooq archive (primary source) ---------------------------------
# Stooq publishes a free daily ZIP containing the full GPW history (stocks +
# indices + bonds + funds + futures). The user unpacks it under
# data/stooq/data/daily/pl/. Files are CSV with header
#   <TICKER>,<PER>,<DATE>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>,<VOL>,<OPENINT>
# DATE is YYYYMMDD (no separators). 426 stocks + WIG, WIG20, etc. as of 2026-05.
#
# This is the preferred source: same price semantics as the original pipeline
# (raw close, no Yahoo Adjusted-Close drift), full coverage including indices,
# zero network calls, no rate limits. Archive root is configurable via
# Sys.getenv("DR_STOOQ_ARCHIVE", unset = "data/stooq/data/daily/pl").

.stooq_archive_root <- function() {
  Sys.getenv("DR_STOOQ_ARCHIVE", unset = "data/stooq/data/daily/pl")
}

.stooq_local_path <- function(symbol) {
  root <- .stooq_archive_root()
  fname <- paste0(tolower(symbol), ".txt")
  subdir <- if (.is_index_local(symbol)) "wse indices" else "wse stocks"
  file.path(root, subdir, fname)
}

# Indices are checked separately because the archive places them under
# `wse indices/`. Listed names match the WIG family available in the bundle.
.is_index_local <- function(s) {
  toupper(s) %in% c(
    "WIG", "WIG20", "WIG30", "MWIG40", "SWIG80", "WIGDIV", "WIG20TR",
    "WIG_BANKI", "WIG_BUDOW", "WIG_CHEMIA", "WIG_ENERG", "WIG_GORNIC",
    "WIG_INFO", "WIG_MEDIA", "WIG_MOTO", "WIG_NRCHOM", "WIG_PALIWA",
    "WIG_SPOZYW", "WIG_TELKOM", "WIG_LEKI", "WIG_GAMES5", "WIG_ODZIEZ"
  )
}

stooq_local_dw <- function(symbol, close_only = TRUE) {
  path <- .stooq_local_path(symbol)
  if (!file.exists(path)) {
    stop(sprintf("local stooq archive missing %s (looked in %s)",
                 symbol, path))
  }
  raw <- read_csv(path, show_col_types = FALSE)
  expected <- c("<TICKER>", "<DATE>", "<OPEN>", "<HIGH>", "<LOW>", "<CLOSE>")
  if (!all(expected %in% names(raw))) {
    stop(sprintf("local stooq file %s has unexpected columns: %s",
                 path, paste(names(raw), collapse = ", ")))
  }
  df <- tibble(
    Date  = as.Date(as.character(raw[["<DATE>"]]), format = "%Y%m%d"),
    Open  = as.numeric(raw[["<OPEN>"]]),
    High  = as.numeric(raw[["<HIGH>"]]),
    Low   = as.numeric(raw[["<LOW>"]]),
    Close = as.numeric(raw[["<CLOSE>"]])
  )
  df <- df[!is.na(df$Date), ]
  if (nrow(df) > 0 && any(!is.na(df$Close))) {
    df$Close <- zoo::na.locf(df$Close, na.rm = FALSE)
  }
  if (close_only) {
    safe_col_name <- make.names(gsub("[^[:alnum:] ]", "", symbol))
    df <- df %>%
      dplyr::select(Date, Close) %>%
      dplyr::rename_with(~safe_col_name, .cols = Close)
  }
  df
}


# ---- yahoo fetcher (default for individual GPW stocks) ---------------------
# Stooq applied a hard paywall to the public CSV endpoint in May 2026 (returns
# "Uzyskaj apikey…" instead of OHLC) and the apikey "signup" link is dead.
# Yahoo Finance still serves Polish stocks under the `.WA` suffix without
# auth, via quantmod::getSymbols. Verified for: 11B, KGH, PKN, ALE, CDR, etc.
# Yahoo does NOT have WIG / WIG20 / mWIG40 (404) — those still go through
# stooq_dw via the dispatcher below.
#
# Note on price semantics: Yahoo returns split-adjusted Close (the `.Close`
# column is already adjusted for splits, though not dividends — `.Adjusted`
# would be both). Stooq returned raw Close. For the SMA200 chart and EMA-based
# trend indicator the difference is invisible (split events are rare on GPW
# and the indicator depends on EMA2 vs EMA200, level-invariant).

yahoo_dw <- function(symbol, close_only = TRUE) {
  if (!requireNamespace("quantmod", quietly = TRUE)) {
    stop("yahoo_dw needs the 'quantmod' package; install.packages('quantmod')")
  }
  yahoo_sym <- if (grepl("\\.", symbol)) symbol else paste0(symbol, ".WA")

  res <- quantmod::getSymbols(
    yahoo_sym, src = "yahoo",
    from = "2015-01-01", to = Sys.Date(),
    auto.assign = FALSE
  )

  if (is.null(res) || nrow(res) == 0) {
    stop(sprintf("yahoo returned no data for %s", yahoo_sym))
  }

  cols <- colnames(res)
  pick <- function(suffix) {
    nm <- grep(paste0("\\.", suffix, "$"), cols, value = TRUE)[1]
    if (is.na(nm)) rep(NA_real_, nrow(res)) else as.numeric(res[, nm])
  }

  df <- tibble(
    Date  = as.Date(zoo::index(res)),
    Open  = pick("Open"),
    High  = pick("High"),
    Low   = pick("Low"),
    Close = pick("Close")
  )

  if (nrow(df) > 0 && any(!is.na(df$Close))) {
    df$Close <- zoo::na.locf(df$Close, na.rm = FALSE)
  }

  if (close_only) {
    safe_col_name <- make.names(gsub("[^[:alnum:] ]", "", symbol))
    df <- df %>%
      dplyr::select(Date, Close) %>%
      dplyr::rename_with(~safe_col_name, .cols = Close)
  }
  df
}


# ---- dispatcher -------------------------------------------------------------
# Single-ticker entry point used by both the bulk pipeline (get_stooq_data
# called with 100 tickers from get_prices2.R) and direct single-symbol calls
# from calc_*_index.R for WIG / WIG20.
#
# Source priority (default):
#   1. Local stooq archive at DR_STOOQ_ARCHIVE (data/stooq/data/daily/pl/) —
#      preferred when the file exists. Same semantics as the old pipeline,
#      no network, includes indices.
#   2. Yahoo Finance via quantmod — fallback for individual stocks the local
#      archive doesn't have. Doesn't carry GPW indices.
#   3. Remote stooq CSV — last resort, currently paywalled.
#
# Override with Sys.setenv(DR_PRICE_SOURCE = "yahoo" | "stooq" | "local")
# to force a single source.

.fetch_one <- function(symbol) {
  src <- tolower(Sys.getenv("DR_PRICE_SOURCE", unset = ""))

  if (identical(src, "yahoo"))  return(yahoo_dw(symbol))
  if (identical(src, "stooq"))  return(stooq_dw(symbol))
  if (identical(src, "local"))  return(stooq_local_dw(symbol))

  # Default: try local archive first, then Yahoo for stocks, then remote stooq.
  local_path <- .stooq_local_path(symbol)
  if (file.exists(local_path)) return(stooq_local_dw(symbol))
  if (.is_index_local(symbol)) {
    # Indices not in local archive — last-resort remote stooq.
    return(stooq_dw(symbol))
  }
  tryCatch(
    yahoo_dw(symbol),
    error = function(e) {
      message(sprintf("  yahoo failed for %s (%s); trying remote stooq",
                      symbol, conditionMessage(e)))
      stooq_dw(symbol)
    }
  )
}


#' @export
get_stooq_data <- function(ticks, fail_threshold = 0.5) {
  # Single-symbol call (e.g. calc_*_index.R fetching WIG20). Propagate errors
  # so the caller can tryCatch — no bulk threshold logic.
  if (length(ticks) == 1) {
    return(.fetch_one(ticks))
  }

  # Bulk fetch. Throttle protects stooq quota when DR_PRICE_SOURCE=stooq;
  # for Yahoo the limit isn't an issue but the pacing keeps logs readable.
  fetch <- slowly(
    function(t) tryCatch(.fetch_one(t), error = function(e) {
      message(sprintf("  ! %s: %s", t, conditionMessage(e)))
      NULL
    }),
    rate = rate_delay(0.6)
  )

  src_label <- if (identical(tolower(Sys.getenv("DR_PRICE_SOURCE", unset = "")), "stooq")) {
    "stooq"
  } else {
    "yahoo (stooq for indices)"
  }
  message(sprintf("Fetching %d tickers from %s...", length(ticks), src_label))
  xy <- map(ticks, fetch)

  ok <- !sapply(xy, is.null)
  n_ok <- sum(ok)
  n_total <- length(ticks)
  message(sprintf("Fetched %d / %d tickers (%.0f%% success)",
                  n_ok, n_total, 100 * n_ok / n_total))

  if (n_ok / n_total < (1 - fail_threshold)) {
    stop(sprintf(
      "fetch success rate %.0f%% below threshold %.0f%%; aborting to protect existing data",
      100 * n_ok / n_total, 100 * (1 - fail_threshold)
    ))
  }

  xy <- xy[ok]

  # Master Date axis: prefer WIG (best historical coverage). Goes through the
  # dispatcher, so it'll use the local archive if available.
  W20 <- tryCatch(
    .fetch_one("WIG"),
    error = function(e) {
      message("  ! WIG fetch failed, using first ticker's date axis: ",
              conditionMessage(e))
      NULL
    }
  )

  master_t <- if (!is.null(W20) && "Date" %in% names(W20)) {
    tibble(Date = W20$Date)
  } else {
    tibble(Date = xy[[1]]$Date)
  }

  for (n in seq_along(xy)) {
    if (n %% 10 == 0 || n == length(xy)) {
      message(sprintf("  joined %d/%d", n, length(xy)))
    }
    master_t <- master_t %>% left_join(xy[[n]], by = "Date")
  }
  master_t
}


#' @export
get_table <- function(table_url) {
  table_path <- '//*[@id="profile-finreports"]/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  Sys.sleep(3)
  raw_html %>% html_nodes(xpath = table_path) %>% html_table()
}


#' @export
get_companies <- function(table_url) {
  table_path <- '//*[@id="right-content"]/div/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  raw_html %>% html_nodes(xpath = table_path) %>% html_table()
}

#' @export
get_companies2 <- function(table_url) {
  table_path <- '//*[@id="main-props"]/div/main/div/div[3]/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  raw_html %>% html_nodes(xpath = table_path) %>% html_table()
}


#' @export
get_companies_links <- function(table_url) {
  table_path <- '//*[@id="right-content"]/div/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |>
    clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |>
    select(ticker) |>
    filter(nchar(ticker) == 3)

  c_links <- tibble(
    link = paste0(
      "https://www.biznesradar.pl",
      raw_html |>
        html_elements(xpath = table_path) |>
        html_elements(".bvalue") |>
        html_elements("a") |>
        html_attr("href"),
      ",",
      "Q"
    )
  )

  c_links <- c_links |>
    filter(
      link !=
        "https://www.biznesradar.pl/raporty-finansowe-rachunek-zyskow-i-strat/SVRS,Q"
    )

  companies$link <- c_links$link
  companies
}


#' @export
get_companies_links_bilans <- function(table_url) {
  table_path <- '//*[@id="right-content"]/div/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |>
    clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |>
    select(ticker) |>
    filter(nchar(ticker) == 3)

  c_links <- tibble(
    link = paste0(
      "https://www.biznesradar.pl",
      raw_html |>
        html_elements(xpath = table_path) |>
        html_elements(".bvalue") |>
        html_elements("a") |>
        html_attr("href"),
      ",",
      "Q"
    )
  )

  c_links <- c_links |>
    filter(link != "https://www.biznesradar.pl/raporty-finansowe-bilans/SVRS,Q")

  companies$link <- c_links$link
  companies
}


#' @export
get_companies_links_cf <- function(table_url) {
  table_path <- '//*[@id="right-content"]/div/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |>
    clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |>
    select(ticker) |>
    filter(nchar(ticker) == 3)

  c_links <- tibble(
    link = paste0(
      "https://www.biznesradar.pl",
      raw_html |>
        html_elements(xpath = table_path) |>
        html_elements(".bvalue") |>
        html_elements("a") |>
        html_attr("href"),
      ",",
      "Q"
    )
  )

  c_links <- c_links |>
    filter(
      link !=
        "https://www.biznesradar.pl/raporty-finansowe-przeplywy-pieniezne/SVRS,Q"
    )

  companies$link <- c_links$link
  companies
}


#' @export
clean_rzis <- function(tb) {
  tb |>
    clean_names() |>
    rotate_df(cn = TRUE) |>
    as_tibble(.name_repair = "unique") |>
    clean_names() |>
    mutate(data_publikacji = as.Date(data_publikacji)) |>
    mutate(across(przychody_ze_sprzedazy:ebitda, str_remove_all, " ")) |>
    mutate(across(przychody_ze_sprzedazy:ebitda, parse_number))
}


#' @export
clean_bilans <- function(tb) {
  tb |>
    clean_names() |>
    mutate(x = paste0(x, 1:nrow(tb))) |>
    rotate_df(cn = TRUE) |>
    as_tibble() |>
    clean_names() |>
    mutate(data_publikacji1 = as.Date(data_publikacji1)) |>
    mutate(across(aktywa_trwale2:pasywa_razem36, str_remove_all, " ")) |>
    mutate(across(aktywa_trwale2:pasywa_razem36, parse_number)) |>
    select(-wartosc_firmy4, -aktywa_z_tytulu_prawa_do_uzytkowania6)
}

#' @export
clean_cf <- function(tb) {
  tb |>
    clean_names() |>
    rotate_df(cn = TRUE) |>
    as_tibble() |>
    clean_names() |>
    mutate(data_publikacji = as.Date(data_publikacji)) |>
    mutate(across(
      przeplywy_pieniezne_z_dzialalnosci_operacyjnej:free_cash_flow,
      str_remove_all,
      " "
    )) |>
    mutate(across(
      przeplywy_pieniezne_z_dzialalnosci_operacyjnej:free_cash_flow,
      parse_number
    ))
}


#' @export
get_companies_links_cv <- function(table_url) {
  table_path <- '//*[@id="right-content"]/div/table'

  set_config(add_headers(
    `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36"
  ))

  get_delayed <- slowly(~ GET(.), rate = rate_delay(3))

  get_result <- get_delayed(table_url)

  raw_html <- read_html(get_result)

  companies <- raw_html |> html_elements(xpath = table_path) |> html_table()
  companies <- companies[[1]] |>
    clean_names() |>
    separate(col = profil, into = c("ticker", "name"), sep = " ") |>
    select(ticker) |>
    filter(nchar(ticker) == 3)

  c_links <- tibble(
    link = paste0(
      "https://www.biznesradar.pl",
      raw_html |>
        html_elements(xpath = table_path) |>
        html_elements(".bvalue") |>
        html_elements("a") |>
        html_attr("href")
    )
  )

  c_links <- c_links |>
    filter(
      link != "https://www.biznesradar.pl/wskazniki-wartosci-rynkowej/SVRS"
    )

  companies$link <- c_links$link
  companies
}


#' @export
clean_cv <- function(tb) {
  tb |>
    clean_names() |>
    names() -> col_names

  col_names_ok <- col_names[2:(length(col_names) - 1)]

  tmp <- tb |>
    clean_names() |>
    rotate_df(cn = TRUE) |>
    as_tibble() |>
    clean_names()
  tmp <- tmp[-nrow(tmp), ]

  tmp <- tmp |>
    mutate(okres = col_names_ok) |>
    select(liczba_akcji, okres) |>
    mutate(okres = str_remove_all(okres, "x")) |>
    separate(col = okres, into = c("rok", "kwartal", "mies", "rok_skr")) |>
    mutate(rok = as.numeric(rok)) |>
    mutate(kwartal = as.numeric(str_remove_all(kwartal, "q"))) |>
    select(-mies, -rok_skr) |>
    mutate(liczba_akcji = str_remove_all(liczba_akcji, " ")) |>
    mutate(liczba_akcji = parse_number(liczba_akcji))

  tmp
}
