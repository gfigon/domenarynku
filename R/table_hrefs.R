library(rvest)

# Czekamy aż tabela będzie obecna
page <- read_html_live("https://www.biznesradar.pl/gielda/akcje_gpw")
Sys.sleep(5)


tables <- page %>% html_elements("table")

c_links <- tables[[1]] |> html_elements("td") |> html_elements("a") |> html_attrs()


tabela <- tables[[1]] %>% html_table()

companies_table <- tabela |> clean_names() |> select(profil, kurs, wolumen, obrot) |> 
  separate(col = profil, into = c("ticker", "name"), sep = " ")

companies_table <- companies_table[-1,]
  
  
companies_table <- companies_table |> mutate(href = map_chr(c_links, ~ .[1])) |> 
  mutate(firma = map_chr(c_links, ~ .[2]))
  
companies_table <- companies_table |> 
  filter(nchar(ticker) == 3) |>
  mutate(across(kurs:obrot, str_remove_all, " ")) |>
  mutate(across(kurs:obrot, parse_number)) |> 
  mutate(href = paste0("https://www.biznesradar.pl", href))


companies_table |> saveRDS("data/table_hrefs.RDS")
