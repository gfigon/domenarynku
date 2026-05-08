#!/usr/bin/env Rscript
# Remap broken `image:` references in post front-matter.
#
# For each `posts/*/index.qmd`:
# - If `image:` value resolves to an existing file (or is an external URL),
#   keep it.
# - Otherwise, remap by post slug pattern to a themed banner from
#   `images/posts/`. If no banner pattern matches, drop the line entirely
#   (the homepage listing's `image-placeholder` will fall back to the
#   generic news-placeholder.svg).
# - Empty or broken `og_image:` lines are dropped (they would only emit
#   empty Open Graph meta tags otherwise).
# - For slug-matching posts that don't have an `image:` line at all, insert
#   one after `date:` so they get a themed thumbnail in the listing.
#
# Idempotent: re-running on already-fixed posts is a no-op.

suppressPackageStartupMessages(library(stringr))

# Resolve project root from this script's location.
.this_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", args, value = TRUE)
  if (length(m)) sub("^--file=", "", m[1]) else NULL
}
.script_path <- .this_script()
if (!is.null(.script_path) && nzchar(.script_path)) {
  setwd(normalizePath(file.path(dirname(.script_path), "..")))
}

banner_for <- function(slug) {
  # Substring match tolerates slug typos (e.g. `rasowka-swiat` missing a 'p').
  if (str_detect(slug, "prasowka-gpw") ||
      identical(slug, "2026-02-06-prasowka-popoludniowa-test")) {
    return("../../images/posts/prasowka-gpw.svg")
  }
  if (str_detect(slug, "rasowka-swiat") ||
      str_detect(slug, "flesz-ze-swiata")) {
    return("../../images/posts/prasowka-swiat.svg")
  }
  if (identical(slug, "2024-11-21-indeks-trendow-analiza")) {
    return("../../images/posts/makro.svg")
  }
  NA_character_
}

resolves_path <- function(post_dir, value) {
  v <- str_trim(str_replace_all(value, '^["\']|["\']$', ""))
  if (!nzchar(v)) return(FALSE)
  if (str_detect(v, "^(https?://|data:)")) return(TRUE)
  file.exists(file.path(post_dir, v))
}

posts <- list.files("posts", pattern = "^index\\.qmd$",
                    recursive = TRUE, full.names = TRUE)

img_re <- "^image:\\s*(.*?)\\s*$"
og_re  <- "^og_image:\\s*(.*?)\\s*$"

changed <- 0L
added   <- 0L

for (p in posts) {
  src      <- readLines(p, warn = FALSE)
  slug     <- basename(dirname(p))
  post_dir <- dirname(p)
  new      <- src

  # Rewrite or drop existing image: lines.
  for (i in str_which(new, img_re)) {
    val <- str_match(new[i], img_re)[1, 2]
    if (resolves_path(post_dir, val)) next
    b <- banner_for(slug)
    new[i] <- if (!is.na(b)) paste0("image: ", b) else ""
  }

  # Drop empty / broken og_image lines.
  for (i in str_which(new, og_re)) {
    val <- str_match(new[i], og_re)[1, 2]
    if (!resolves_path(post_dir, val)) new[i] <- ""
  }

  # Insert image: line for slug-matching posts that don't have one.
  has_image <- any(str_detect(new, "^image:"))
  if (!has_image) {
    b <- banner_for(slug)
    if (!is.na(b)) {
      date_idx  <- str_which(new, "^date:")[1]
      title_idx <- str_which(new, "^title:")[1]
      target <- if (!is.na(date_idx)) date_idx else title_idx
      if (!is.na(target)) {
        new <- append(new, paste0("image: ", b), after = target)
        added <- added + 1L
      }
    }
  }

  # Collapse runs of blank lines created by removed entries.
  if (any(!nzchar(new))) {
    keep <- rep(TRUE, length(new))
    blanks <- !nzchar(new)
    for (i in seq_along(new)[-1]) {
      if (blanks[i] && blanks[i - 1]) keep[i] <- FALSE
    }
    new <- new[keep]
  }

  if (!identical(new, src)) {
    writeLines(new, p)
    changed <- changed + 1L
  }
}

cat(sprintf("Fixed image fields in %d of %d posts (%d newly added).\n",
            changed, length(posts), added))
