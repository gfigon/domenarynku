#box::unload(gpw)
library(tidyverse)
library(janitor)
box::use(./mod/gpw)


# system("Rscript R/read_table_bisnesradar.R")
# 
# tabela <- readRDS("data/tabela.RDS")
# 
# companies_table <- tabela |> clean_names() |> select(profil, kurs, wolumen, obrot) |> separate(col = profil, into = c("ticker", "name"), sep = " ") |> 
#   filter(nchar(ticker) == 3) |> 
#   mutate(across(kurs:obrot, str_remove_all, " ")) |> 
#   mutate(across(kurs:obrot, parse_number)) 






#companies_filtered <- companies_table |> arrange(desc(obrot))

#tickers_100_selected <- companies_filtered[1:100,]$ticker
#tickers_100_selected |> saveRDS("data/tickers_100_selected.RDS")

tickers_100 <- readRDS("data/tickers_100_selected.RDS")
price_data <- gpw$get_stooq_data(tickers_100)

filter_na <- function(x){sum(tail(x), na.rm = TRUE) > 0}

tick_filter <- map_lgl(price_data[,-1], filter_na)
price_data <- price_data[,c(TRUE,tick_filter)]
price_data |> saveRDS("data/prices100.RDS")




