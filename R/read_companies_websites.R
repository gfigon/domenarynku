library(rvest)
library(tidyverse)
library(ellmer)
library(polite)
library(ragnar)

companies <- readRDS("data/gpw_companies.RDS")

table_hrefs <- readRDS("data/table_hrefs.RDS") |> rename(nazwa = firma)


all_data <- companies |> inner_join(table_hrefs, by = "nazwa")

#rvest
# read_c_website <- function(c_href) {
#   polite_get <- politely(read_html, user_agent = "Mozilla/5.0")
#   page <- polite_get(c_href, delay = 1, verbose = TRUE)
#
#   page
# }
#
#
# c_websites <- map(all_data$www, possibly(read_c_website, otherwise = NA))

#ragnar

# read_c_website_rag <- function(c_href) {
#   page <- read_as_markdown(c_href)
#
#   page |>
#     markdown_chunk(
#       target_size = Inf
#     )
# }
#
#
# c_websites_rag <- map(
#   all_data$www,
#   possibly(read_c_website_rag, otherwise = NA)
# )

library(R.utils)

read_c_website_rag <- function(c_href) {
  # Timeout 30 sekund - jeśli strona nie odpowie, zwróci błąd
  withTimeout(
    {
      page <- read_as_markdown(c_href)
      page |> markdown_chunk(target_size = Inf)
    },
    timeout = 30
  ) # 30 sekund na każdy URL
}

# Teraz map z possibly złapie błąd timeout i zwróci NA
c_websites_rag <- map(
  all_data$www,
  possibly(read_c_website_rag, otherwise = NA),
  .progress = TRUE
)


chat_rag <- chat_openai(
  model = "gpt-4.1-mini",
  system_prompt = "Jesteś doradcą inwestycyjnym na rynku akcji. Analizujesz strony www spółek giełdowych,
  żeby uzyskać informacje interesujące potencjalnych inwestorów. Na tej podstawie przygotowujesz własny opis
  każdej analizowanej firmy według konkretnych kryteriów w języku polskim."
)

type_company <- type_object(
  "CompanyDescr",
  about = type_string(
    "Czym się firma zajmuje - opisz charakter działalności firmy."
  ),
  products = type_string(
    "Produkty lub usługi oferowane przez firmę"
  ),
  resources = type_string(
    "Jakich zasobów firma używa, żeby efektywnie prowadzić działalność?"
  ),
  usefull_url = type_string(
    "Adres podstrony na stronie www, który może zawierać ważne z punktu inwestora informacje."
  )
)


type_all_proj_parts <- type_array(items = type_company)


interpret_website <- function(website) {
  result_data <- tibble()
  if (is_tibble(website)) {
    result_data <- chat_rag$chat_structured(
      website$text,
      type = type_all_proj_parts,
      echo = "none"
    )
    result_data
  } else {
    NA
  }
}

#sum(map_lgl(c_websites_rag, is_tibble))

www_data <- map(
  c_websites_rag,
  possibly(interpret_website, otherwise = NA),
  .progress = TRUE
)
