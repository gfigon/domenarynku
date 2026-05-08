#!/usr/bin/env Rscript
# Normalize category casing/spelling across all post YAML front-matter.
#
# Idempotent: re-running won't double-apply. Touches only the inline
# `categories: [a, b, c]` line in each post's front-matter and dedupes
# the resulting array.
#
# Canonical scheme: sentence case for words, all-caps for acronyms.

suppressPackageStartupMessages(library(stringr))

# Resolve project root from this script's location so it works whether
# invoked as `Rscript scripts/normalize_categories.R` from project root
# or by absolute path.
.this_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", args, value = TRUE)
  if (length(m)) sub("^--file=", "", m[1]) else NULL
}
.script_path <- .this_script()
if (!is.null(.script_path) && nzchar(.script_path)) {
  setwd(normalizePath(file.path(dirname(.script_path), "..")))
}

# Migration map (case-sensitive lookup against unquoted token).
CAT_MAP <- c(
  "świat"               = "Świat",
  "swiat"               = "Świat",
  "Wiadomości Światowe" = "Świat",
  "News"                = "Świat",
  "prasówka"            = "Prasówka",
  "gpw"                 = "GPW",
  "geopolityka"         = "Geopolityka",
  "makroekonomia"       = "Makroekonomia",
  "Makro"               = "Makroekonomia",
  "giełda"              = "Giełda",
  "ropa"                = "Ropa"
)

normalize_inline <- function(items_str) {
  raw <- str_trim(str_split(items_str, ",", simplify = TRUE)[1, ])
  raw <- raw[nzchar(raw)]
  unquoted <- str_replace_all(raw, '^["\']|["\']$', "")
  mapped <- ifelse(unquoted %in% names(CAT_MAP),
                   unname(CAT_MAP[unquoted]),
                   unquoted)
  paste(unique(mapped), collapse = ", ")
}

posts <- list.files("posts", pattern = "^index\\.qmd$",
                    recursive = TRUE, full.names = TRUE)

# Match `categories: [...]` lines and capture the three pieces (prefix,
# inner items, suffix). Anchored to start of line; in source-file context
# this only matches YAML front-matter lines.
cat_re <- "^(categories:\\s*\\[)(.*)(\\]\\s*)$"

changed <- 0L
for (p in posts) {
  src <- readLines(p, warn = FALSE)
  hits <- str_which(src, cat_re)
  if (length(hits) == 0L) next
  new <- src
  for (i in hits) {
    m <- str_match(src[i], cat_re)
    if (!is.na(m[1, 1])) {
      new[i] <- paste0(m[1, 2], normalize_inline(m[1, 3]), m[1, 4])
    }
  }
  if (!identical(new, src)) {
    writeLines(new, p)
    changed <- changed + 1L
  }
}

cat(sprintf("Normalized categories in %d of %d posts.\n",
            changed, length(posts)))
