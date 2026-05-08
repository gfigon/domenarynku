# Script to update company profiles categories and headers
# Usage: Rscript scripts/update_profiles.R

# 1. Load Mappings
branze_csv <- read.csv("data/branze_podbranze.csv", stringsAsFactors = FALSE)
sub_to_ind <- setNames(branze_csv$branza, branze_csv$podbranza)
valid_inds <- unique(branze_csv$branza)

# Manual fallback mapping
manual_map <- c(
    "Informatyka" = "Technologie i IT",
    "Oprogramowanie" = "Technologie i IT",
    "Bankowość" = "Finanse",
    "Energetyka" = "Surowce i energia",
    "Górnictwo" = "Surowce i energia",
    "Budownictwo" = "Nieruchomości i budownictwo",
    "Paliwa" = "Surowce i energia",
    "Gry" = "Technologie i IT",
    "Deweloperzy" = "Nieruchomości i budownictwo",
    "Handel" = "Handel i konsumpcja",
    "Surowce" = "Surowce i energia",
    "Finanse" = "Finanse",
    "Surowce i energia" = "Surowce i energia",
    "Przemysł i produkcja" = "Przemysł i produkcja",
    "Nieruchomości i budownictwo" = "Nieruchomości i budownictwo",
    "Technologie i IT" = "Technologie i IT",
    "Handel i konsumpcja" = "Handel i konsumpcja",
    "Zdrowie i farmacja" = "Zdrowie i farmacja",
    "Media i komunikacja" = "Media i komunikacja",
    "Transport i logistyka" = "Transport i logistyka",
    "Rolnictwo i żywność" = "Rolnictwo i żywność",
    "Ochrona środowiska i OZE" = "Ochrona środowiska i OZE",
    "Usługi biznesowe" = "Usługi biznesowe",
    "Media" = "Media i komunikacja",
    "Windykacja" = "Finanse",
    "Hutnictwo" = "Surowce i energia",
    "Usługi finansowe" = "Finanse",
    "Reklama outdoor" = "Media i komunikacja",
    "Przemysł" = "Przemysł i produkcja"
)

all_mappings <- c(sub_to_ind, manual_map)

# 2. Iterate Files
files <- list.files("spolki", pattern = "\\.qmd$", full.names = TRUE)

for (f in files) {
    content <- readLines(f)

    # A. Determine correct industry
    cat_line_idx <- grep("^categories:", content)
    if (length(cat_line_idx) == 0) {
        next
    }

    cat_line <- content[cat_line_idx[1]]
    cats_str <- gsub("categories: \\[(.*)\\]", "\\1", cat_line)
    current_cats <- trimws(unlist(strsplit(cats_str, ",")))

    final_cat <- NA
    # Try to find industry in current categories
    # 1. Direct match with Industry
    ind_match <- intersect(current_cats, valid_inds)
    # 2. Match via mapping
    map_match <- intersect(current_cats, names(all_mappings))
    mapped_inds <- if (length(map_match) > 0) all_mappings[map_match] else c()

    found_inds <- unique(c(ind_match, mapped_inds))

    if (length(found_inds) > 0) {
        final_cat <- found_inds[1]
    } else {
        # If explicit manual mapping fails, try to see if any part of the string matches known industries
        # This is a bit safer fallback
        print(paste(
            "WARNING: No mapping found for",
            f,
            ":",
            paste(current_cats, collapse = ", ")
        ))
        next
    }

    print(paste("Updating", basename(f), "to", final_cat))

    # B. Update YAML
    content[cat_line_idx[1]] <- paste0("categories: [", final_cat, "]")

    # C. Update Header
    # Search for the header line which usually contains "Branża:" and "Podbranża:"
    # It's usually inside a ::: {.company-header} block or stand-alone
    # Pattern: ... | **Branża:** ...

    header_idx <- grep("\\*\\*Branża:\\*\\*", content)
    if (length(header_idx) > 0) {
        # We reconstruct the line up to "Branża" and replace the rest
        # CAUTION: The line structure is: [← Spółki GPW]... | **Branża:** ... | **Podbranża:** ...
        # We want to keep everything before **Branża:**
        # Then append **Branża:** [Industry](../spolki-gpw.html#category=Industry)
        # And REMOVE **Podbranża:** section if present.

        line <- content[header_idx[1]]

        # Split by "**Branża:**"
        parts <- strsplit(line, "\\*\\*Branża:\\*\\*")[[1]]
        prefix <- parts[1] # "::: {.company-header}\n[← Spółki GPW]... | "

        # Construct new suffix
        new_suffix <- paste0(
            "[",
            final_cat,
            "](../spolki-gpw.html#category=",
            final_cat,
            ")"
        )

        # Reassemble line. Note: if the line ended with ::: it might be lost if we are not careful?
        # Usually the line ends with the Podbranza link. The closing ::: is often on next line,
        # BUT in the sample file acp.qmd it is separate:
        # 51: [← ...] | **Branża:** ... | **Podbranża:** ...
        # 52: :::
        # So we just need to end the line cleanly.

        content[header_idx[1]] <- paste0(prefix, "**Branża:** ", new_suffix)
    }

    writeLines(content, f)
}
