#box::unload(gpw)
library(tidyverse)
library(janitor)
box::use(./mod/gpw)


#system("Rscript R/read_table_bisnesradar.R")

tabela <- readRDS("data/tabela.RDS")

companies_table <- tabela |> clean_names() |> select(profil, kurs, wolumen, obrot) |> separate(col = profil, into = c("ticker", "name"), sep = " ") |> 
  filter(nchar(ticker) == 3) |> 
  mutate(across(kurs:obrot, str_remove_all, " ")) |> 
  mutate(across(kurs:obrot, parse_number)) 

companies_table |> saveRDS("data/stock_list.RDS")
