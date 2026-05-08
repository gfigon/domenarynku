library(rvest)

# Czekamy aż tabela będzie obecna
page <- read_html_live("https://www.biznesradar.pl/gielda/akcje_gpw")
Sys.sleep(5)


tables <- page %>% html_elements("table")

tabela <- tables[[1]] %>% html_table()
saveRDS(tabela, "data/tabela.RDS")