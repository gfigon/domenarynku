# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

DomenaRynku.pl — a Polish-language Quarto website (https://domenarynku.pl) covering Warsaw Stock Exchange (GPW) analysis: market breadth indices, equal-weighted price indices, sentiment, daily news roundups ("prasówki"), and ~97 per-company profile pages. Content language is Polish; keep generated text and front-matter in Polish unless asked otherwise.

## Tech stack

- Quarto 1.4+ (website project, `_quarto.yml`)
- R 4.5.2 for data fetching, index calculation, and scraping (executed inside `.qmd` chunks and standalone scripts in `R/`)
- Netlify deploys the contents of `_site/` directly from git (see `netlify.toml`)
- Plotly + custom CSS (`styles.css`) for visuals; Klaro + Google Tag Manager wired in `_quarto.yml` `header-includes`

## The deploy model is unusual — read this before committing

Netlify does **not** build the site. It publishes whatever is committed under `_site/`. That means:

- `_site/` **is committed to git** (this is intentional, not a mistake — do not add it to `.gitignore`).
- `R/`, `scripts/`, `data/`, `mod/`, `_freeze/`, `.quarto/`, and all `.RDS` files are gitignored. They live locally only.
- The standard loop is: pull data locally → render Quarto locally → commit the updated `_site/` → push → Netlify serves the new files.
- A clone from GitHub will be missing `R/`, `scripts/`, and `data/`. Do not assume those directories will reappear on another machine; ask the user before "restoring" anything.

`pretty_urls = false` in `netlify.toml` — URLs keep their `.html` so they match the local render.

## Common commands

Render and preview:

```bash
quarto preview                    # local dev server with live reload
quarto render                     # full site build into _site/
quarto render spolki/             # only the company-profile pages
quarto render indeksy/            # only the index pages
quarto render posts/2026-04-14-prasowka-gpw/  # one post
```

Daily data + render + deploy pipeline (`scripts/update_daily.sh`):

```bash
bash scripts/update_daily.sh
```

It runs, in order: `Rscript R/get_prices2.R` → `Rscript R/calc_price_index.R` → `Rscript R/calc_trend_index.R` → `touch spolki/*.qmd` (to defeat `freeze: auto`) → render `spolki/`, `indeksy/`, then full site → `git add . && git commit && git push`.

Run individual R steps standalone with `Rscript R/<file>.R` from the project root.

## Freeze semantics (important when chunks don't re-execute)

- Project default: `execute.freeze: auto` in `_quarto.yml` — chunks re-run only when the source `.qmd` changes.
- `posts/_metadata.yml` sets `freeze: true` — posts **never** re-render automatically once frozen. To force a re-render, edit the post or `touch` it.
- `spolki/_metadata.yml` sets `freeze: auto`. Daily updates must `touch spolki/*.qmd` so refreshed `data/prices100.RDS` gets reflected — that's why the update script does it.
- `_freeze/` holds cached computational output. It is gitignored, so a fresh clone will re-render everything on the next `quarto render`.

## R code organization

- `R/mod/gpw.R` is a [box](https://klmr.me/box/) module. Scripts load it with:
  ```r
  options(box.path = getwd())
  box::use(R/mod/gpw)        # from project root
  # or  box::use(./mod/gpw)  # from inside R/
  ```
  When adding/calling functions from this module, mark exports with `#' @export` and respect the existing import style (`box::use(httr[...], dplyr[...], ...)`).
- Stock price data comes from stooq.pl via `gpw$get_stooq_data(tickers)`; the canonical ticker list lives in `data/tickers_100_selected.RDS`, and the resulting wide price matrix is `data/prices100.RDS`.
- `.qmd` chunks read RDS via relative paths like `../data/prices100.RDS` (because pages live one level down in `spolki/`, `indeksy/`, `sentyment-rynku/`, `posts/<slug>/`). Keep that pattern when adding pages at the same depth.

## Content layout

- `index.qmd` is a Quarto listing of `posts/`, sorted by date desc.
- `posts/<YYYY-MM-DD-slug>/index.qmd` — one folder per post. Front-matter needs `title`, `date`, `categories`, `slug`, `description`. Daily news roundups follow two patterns: `prasowka-gpw` (Polish market) and `prasowka-swiat` (world). News links use `{rel="nofollow"}`.
- `spolki/<ticker-lowercase>.qmd` — one file per company; the master list and DT table is `spolki-gpw.qmd`. Adding a company means: append to the `companies` data frame in `spolki-gpw.qmd`, create `spolki/<ticker>.qmd` (mirror an existing one like `spolki/11b.qmd`), and ensure the ticker is present in `data/prices100.RDS`.
- `indeksy/` — index methodology + interactive charts (reads `data/index_trend.RDS`, `data/index_price.RDS`).
- `sentyment-rynku/` — PL/USA/world sentiment pages (reads `data/sentiment*.RDS`, `data/my_sent_xts*.RDS`).

## SEO / front-matter convention

Pages distinguish the on-page `title` from the `<title>` tag via Quarto's `pagetitle`, and add per-page `<meta name="description">` and `<meta name="keywords">` through `format.html.header-includes`. Match this pattern when creating new pages — see `index.qmd`, `spolki-gpw.qmd`, `spolki/11b.qmd`, `indeksy/indeks-trendow-gpw.qmd` for templates.

## Privacy / analytics

Global `header-includes` in `_quarto.yml` injects Google Consent Mode v2 (defaults to `denied`), the Klaro cookie banner (`klaro-config.js`), and GTM container `GTM-NXN55TCK`. Don't add competing analytics or duplicate these snippets at page level.

## Design system — v2 "Robo Terminal"

`styles.css` is the single source for visual design. Tokens at the top (CSS custom properties prefixed `--dr-*`) define the palette and type scale. The aesthetic is **paper + ink + brass**:

- Paper `#F5EFE4` is the page background everywhere; `paper-2 #EDE5D4` for inset/alt rows.
- Ink `#0A0A0A` is type and structural rules. Body copy is `ink-700`, never pure black.
- Brass `#C9A961` is the only accent — link underlines, eyebrow rules, active TOC marker, callout left-rule. Used surgically; one or two brass touches per screen.
- Bull/bear are muted (`#2f6647` / `#8a2e25`), not traffic-light.
- Type stack: **Instrument Serif** (display, H1/H2 — italic in `brass-deep` for emphasis), **Inter** (body, ≤22px titles, UI), **JetBrains Mono** (tickers, prices, eyebrow labels, all-caps tracked labels, table cells). All three loaded via Google Fonts `@import` at the top of `styles.css`.
- Borders are hairline (`1px`); radii are 0–6px only; **no gradients, no colored shadows**.

### Polish typography conventions (apply in body copy and templates)

- Comma decimal separator: `8,6%`, `289,3 mln zł`.
- Real minus sign for negative percentages: `−20,02%`, not `-20,02%`.
- Currency: `140 zł` — lowercase, space-separated.
- Sentence case for headings (Polish doesn't use Title Case).
- Polish dates: `21 listopada 2025`. Numeric: `2026-05-06`.

### Per-company news listings (pattern — not yet applied)

The design calls for an "Aktualności o spółce" section on every company profile that lists posts categorized with the ticker. The pattern is documented here but **not yet applied to any `spolki/<ticker>.qmd`** — applying it forces a re-render of that profile's R chunks (the freeze invalidates on file change), and the chunks have no NULL guard against missing `data/prices100.RDS` columns. Apply the pattern only after `Rscript R/get_prices2.R` has produced a fresh `prices100.RDS` that contains the ticker. Pattern:

```yaml
# in front-matter
listing:
  - id: news-<ticker-lowercase>
    contents: ../posts
    type: default
    sort: "date desc"
    max-items: 5
    categories: false
    sort-ui: false
    filter-ui: false
    image-placeholder: ../images/news-placeholder.svg
    fields: [image, date, title, description]
    include:
      categories: "{<TICKER-UPPERCASE>}"
```

```markdown
## Aktualności o spółce

::: {.dr-co-news}
::: {#news-<ticker-lowercase>}
:::
:::
```

The `.dr-co-news` wrapper styles the listing as a compact news rail (smaller thumbnails, hidden description). The listing only renders posts whose `categories` array contains the matching ticker — so the section quietly stays empty until prasówka posts start tagging tickers.

**Rollout note**: any edit to a `spolki/<ticker>.qmd` re-runs its setup chunk against the current `data/prices100.RDS`. The setup chunk in these files has no defensive guards (a missing ticker or NULL `stock_data` triggers `Error in if (y_ago_idx > 0) ... argument is of length zero`). So before applying this pattern across profiles, refresh the data first: `Rscript R/get_prices2.R`. If you only want to ship the design without touching profile data flow, leave the spolki files alone and the pattern documented here.

### News thumbnail fallback

`index.qmd` listing config sets `image-placeholder: images/news-placeholder.svg` so any post without an `image:` field renders the branded hex-mark placeholder instead of a broken `<img>`. Per-company listings under `spolki/` use `../images/news-placeholder.svg`. When a post has a real editorial photo, set `image:` in the post's front-matter and Quarto will use it instead.

### Themed post banners

`images/posts/` contains a small set of branded 16:10 SVG banners aligned to the design tokens (paper or terminal background, hairline grid, mono caption with `.18em` tracking, one brass accent, no shadows or gradients):

- `prasowka-gpw.svg` — WIG20 ticker tape + candle motif (use for daily Polish market roundups)
- `prasowka-swiat.svg` — terminal globe with financial-center nodes (use for world roundups)
- `dywidendy.svg` — coupon stack with PLN amounts (use for dividend posts)
- `wyniki.svg` — earnings KPI grid (use for quarterly results posts)
- `makro.svg` — CPI vs NBP rate dual line (use for macro / inflation / rates posts)

Plus four generic fallbacks at `images/news-fallback-{chart,bars,pln,terminal}.svg` and the universal `images/news-placeholder.svg`.

Use a banner from a post by setting `image:` in its front-matter:

```yaml
---
title: "Prasówka GPW — 14 kwietnia 2026"
date: "2026-04-14 08:30"
image: ../../images/posts/prasowka-gpw.svg
---
```

The path is relative to the post folder (`posts/<slug>/index.qmd` → two levels up to `images/posts/`).

To backfill existing posts (optional — touching them invalidates their freeze and forces a re-render):

```bash
# from project root
for f in posts/*-prasowka-gpw/index.qmd; do
  grep -q '^image:' "$f" || sed -i '' '/^date:/a\
image: ../../images/posts/prasowka-gpw.svg
' "$f"
done

for f in posts/*-prasowka-swiat/index.qmd; do
  grep -q '^image:' "$f" || sed -i '' '/^date:/a\
image: ../../images/posts/prasowka-swiat.svg
' "$f"
done
```

Run only when the freeze re-execution is acceptable (most prasówki are pure markdown; a handful have R chunks — verify before bulk edits).

### Logo assets

The lockup exists in two lengths because a navbar caps imgs at ~48px and the tagline "PORTAL ŚWIADOMEGO INWESTORA" becomes unreadable below ~7px. Splitting fixes both navbar legibility and large-format usage.

- `images/dr-logo-lockup.svg` — **navbar lockup** (compact ~5.8:1, viewBox `0 0 290 50`): hex mark + "DomenaRynku" + ".pl", **no tagline**. Used in `_quarto.yml` `navbar.logo`.
- `images/dr-logo-lockup-light.svg` — same compact lockup, paper text on transparent ink (for dark surfaces).
- `images/dr-logo-lockup-long.svg` — **footer / large-format lockup** (5.625:1, viewBox `0 0 360 64`): same elements plus the brass-rule + tagline. Use anywhere the rendered height is ≥ 64px.
- `images/dr-logo-lockup-long-light.svg` — long lockup, light variant.
- `images/dr-logo-mark.svg` — hexagonal "DR" mark only; favicon.
- The old `images/domenarynku-logo*.svg` files are unused in current config; safe to delete once you confirm nothing external references them.

Navbar `max-height` is set to `48px` in `styles.css` (matches Bootstrap's no-title default). At that size the compact lockup renders ~280×48 with the wordmark at ~29px and ".pl" at ~16px — comfortably readable.

### Categories — canonical scheme

Sentence case for words, all-caps for acronyms. Confirmed canonical tokens (drop in any new post's `categories:` list):

- `Świat` (collapses any of `świat`, `swiat`, `Wiadomości Światowe`, `News`)
- `Prasówka`, `GPW`, `Geopolityka`, `Makroekonomia` (collapses `Makro`), `Giełda`, `Ropa`
- Common nouns stay lowercase Polish: `biznes`, `finanse`, `dywidendy`, `cła`, `miedź`, `obronność`, `polska`
- Acronyms uppercase: `WIG20`, `USA`, `KGHM`, `PGE`, `ESPI`, `SIPRI`
- Proper nouns: `Wall Street`, `Trump`, `Orlen`, `Dino`, `Azoty`, `Agora`, `Alior Bank`, `Sentyment`

Migration script at `scripts/normalize_categories.R` is idempotent — re-run any time after creating new posts to enforce the scheme:

```bash
Rscript scripts/normalize_categories.R
```

The script also dedupes within each post's array (so collapsing `[Świat, swiat]` into `[Świat, Świat]` self-corrects to `[Świat]`).

### Post thumbnails — coverage policy

Every post must show a thumbnail in the homepage listing. Two layers:

1. Posts whose slug matches a known type (`*prasowka-gpw*`, `*rasowka-swiat*` (typo-tolerant), `*flesz-ze-swiata*`) get a themed banner via `image:` pointing at `images/posts/{prasowka-gpw,prasowka-swiat,…}.svg`.
2. Posts that don't match a pattern AND have no `image:` field fall back to `images/news-placeholder.svg` via the listing's `image-placeholder:` config in `index.qmd`.

`scripts/fix_post_images.R` enforces both:
- Rewrites broken `image:` paths to themed banners or removes them entirely (placeholder kicks in).
- Inserts an `image:` line for slug-matching posts that didn't have one.
- Removes empty/broken `og_image:` lines.

Idempotent — re-run after adding posts:

```bash
Rscript scripts/fix_post_images.R
```

## Price-data source — local stooq archive (primary), Yahoo + remote stooq fallback

Stooq.pl applied a hard paywall to its public CSV endpoint in May 2026: `https://stooq.pl/q/d/l/?s=...&i=d` returns Polish text telling you to obtain an apikey, but the "signup" link 302s back to itself with no actual signup path. The paywall is quota-based — a fresh IP browsing in incognito works once or twice, then trips the moment a script does a few sequential libcurl requests.

Workaround: stooq publishes a **free downloadable ZIP archive** with the full GPW history. User unpacks it to `data/stooq/data/daily/pl/` (gitignored alongside the rest of `data/`). 426 stocks under `wse stocks/` + all WIG-family indices under `wse indices/`, refreshed daily by re-downloading the bundle.

`R/mod/gpw.R` dispatches per-symbol with this priority (default):

1. **Local stooq archive** — `stooq_local_dw(symbol)` reads `<archive_root>/wse stocks/<lowercase>.txt` (or `wse indices/<lowercase>.txt` for indices). Same price semantics as the original pipeline (raw Close, no Yahoo Adjusted-Close drift), zero network calls, no rate limits, full history back to ~1991. Archive root configurable via `Sys.getenv("DR_STOOQ_ARCHIVE", unset = "data/stooq/data/daily/pl")`.
2. **Yahoo Finance** — fallback for individual stocks the local archive doesn't have (e.g. CCC after delisting). Via `quantmod::getSymbols("<ticker>.WA", src = "yahoo")`.
3. **Remote stooq CSV** — last resort. Currently always paywalled, included only for completeness / future apikey support.

Override the priority with `Sys.setenv(DR_PRICE_SOURCE = "yahoo" | "stooq" | "local")` to force a single source (debug / A/B).

### Refresh workflow

When stooq publishes the daily bundle, replace `data/stooq/` with the new download. `Rscript R/get_prices2.R` then re-reads the local files — no network calls, fast (< 10s for 100 tickers).

### Notes & caveats

- **Column naming for digit-prefix tickers**: `make.names("11B") = "X11B"`. So in `prices100.RDS` the column for 11B is `X11B`, for 4MS is `X4MS`. `spolki/11b.qmd` and `spolki/4ms.qmd` have a fallback that retries the lookup via `make.names(ticker)`. `spolki-gpw.qmd` already uses `X11B`/`X4MS` in its ticker list.
- **`indeksy/*.qmd` column names**: `R/calc_trend_index.R` and `R/calc_price_index.R` build the merged xts with explicit column names (`index_trend_perc`, `W20`, `WIG` / `unweighted_index`, `W20`, `WIG`) so the qmd pages can do `all_data$W20`, `all_data$WIG` directly. Earlier versions left R's auto-generated `structure.c.…` mangled names; do not regress that.
- **WIG/WIG20 graceful degrade**: both `calc_*_index.R` wrap WIG/WIG20 fetches in `tryCatch`. If neither local nor remote source has them, `data/index_*.RDS` is written without those columns and the indeksy charts render with just the project's own indicator.

## Stooq fetcher resilience

The `gpw$stooq_dw` / `gpw$get_stooq_data` pair was rewritten on 2026-05-08 after a silent failure on 2026-05-05 wrote `NULL` to `data/prices100.RDS` (44 bytes), breaking every company profile. Behavior contract now:

- **Fail loud, never silent NULL.** A paywall response (stooq returns "Uzyskaj apikey…" instead of CSV when the IP gets soft-throttled) raises a classified error. The caller maps per-ticker errors to NULL-and-skip, but the *bulk* fetch in `get_stooq_data` aborts with a clear message if the success rate falls below 50%.
- **Throttle**: 0.6s between requests via `purrr::slowly(rate_delay(0.6))`. 100 tickers stay under stooq's anonymous quota.
- **Retry**: each request gets 3 attempts with exponential backoff for 5xx and network errors.
- **Optional cookie**: `Sys.getenv("STOOQ_COOKIE")` is used as `PHPSESSID` if set, defense-in-depth for cases where the IP gets banned and only a logged-in session works. Not normally needed.
- **Realistic User-Agent**: a current Chrome string instead of the bare `Mozilla/5.0` that was being filtered.

`R/get_prices2.R` does an **atomic save**: writes to `data/prices100.RDS.tmp`, validates that ≥80 tickers were retained, then `file.rename()`s onto the canonical name. If validation fails, the previous good `prices100.RDS` is preserved. The old `filter_na` was relaxed: instead of `sum(tail(x, 6)) > 0` (a one-week trading halt killed the ticker), it now keeps any ticker with at least one non-NA close in the last 30 days.

Company profiles (`spolki/*.qmd`) are now defensive: setup and chart chunks have a `# stock_data guard v1` block that early-exits with placeholder values when `stock_data` is NULL or has < 2 rows. So a single missing ticker no longer halts the whole render. Migration via `scripts/harden_company_profiles.R` (idempotent — re-runnable after creating new profiles).

## Cron-driven news roundups

Per `.PROJECT_LOG.md`, three scheduled jobs generate posts:
- 08:20 Mon–Fri — Prasówka DomenaRynku.pl (PL research)
- 08:25 daily — Prasówka GPW (PL with fact-check)
- 11:00 daily — Prasówka Światowa (world)

House rules for these posts (from project log): every fact must be backed by 2 sources, dated within the last 3 days, and outbound source links carry `rel="nofollow"`. No `[ZWERYFIKOWANE]` or other verification tags should appear in the published prose.
