library(rvest)
library(tidyverse)

library(polite)


table_hrefs <- readRDS("data/table_hrefs.RDS")

c_link <- "https://www.biznesradar.pl/notowania/4MS"

read_c_data <- function(c_href) {
  polite_get <- politely(read_html, user_agent = "Mozilla/5.0")
  page <- polite_get(c_href, delay = 1, verbose = TRUE)

  tmp_table <- page |>
    html_element(
      xpath = '//*[(@id = "left-content")]//*[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]'
    ) |>
    html_table() |>
    t() |>
    as_tibble()

  colnames(tmp_table) <- tmp_table[1, ]

  tmp_table <- tmp_table |> clean_names() |> select(1:14)
  tmp_row <- tmp_table[2, ]
}


c_data <- map_df(table_hrefs$href[1:136], read_c_data) |> bind_rows()


c_data2 <- map_df(table_hrefs$href[138:200], read_c_data) |> bind_rows()

c_data3 <- map_df(table_hrefs$href[201:300], read_c_data) |> bind_rows()

c_data4 <- map_df(
  table_hrefs$href[301:length(table_hrefs$href)],
  read_c_data
) |>
  bind_rows()


all_data <- bind_rows(c_data, c_data2, c_data3, c_data4)


all_data |> select(1:14) |> saveRDS("data/gpw_companies.RDS")
