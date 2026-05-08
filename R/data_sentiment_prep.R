#box::unload(gpw)
library(tidyverse)
box::use(./mod/gpw)
library(xts)





tickers_port <- c("WIG20", "WIG")



price_data <- gpw$get_stooq_data(tickers_port)

filter_na <- function(x){sum(tail(x), na.rm = TRUE) > 0}

tick_filter <- map_lgl(price_data[,-1], filter_na)
price_data <- price_data[,c(TRUE,tick_filter)]
price_data |> saveRDS("data/prices_port.RDS")



price_data <- readRDS("data/prices_port.RDS")
price_data_xts <- xts(price_data[,-1], order.by = price_data$Date)

price_data_xts <- na.locf(price_data_xts)
price_data_xts <- na.omit(price_data_xts)


my_sent_xts <- readRDS("data/my_sent_xts_all.RDS")

price_data_xts <- price_data_xts[paste0(head(index(my_sent_xts),1), "::", tail(index(my_sent_xts),1))]


my_data_xts <- merge(price_data_xts, my_sent_xts)

my_data_xts <- na.locf(my_data_xts)
my_data_xts <- na.omit(my_data_xts)

my_data_xts$sent_cum <- cumsum(my_data_xts$sent_sum_all)



my_data_xts$rollmean <- rollapplyr(my_data_xts$sent_sum_all, by=1, width=10, FUN=mean, na.rm=TRUE)


my_data_xts$sent_norm <- ((my_data_xts$rollmean - min(my_data_xts$rollmean, na.rm = TRUE))/
  (max(my_data_xts$rollmean, na.rm = TRUE)-min(my_data_xts$rollmean, na.rm = TRUE))) * 100


my_data_xts |> saveRDS("data/sentiment.RDS")

