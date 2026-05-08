
library(tidyverse)
library(xts)
library(zoo)
library(PerformanceAnalytics)
library(TTR)
library(janitor)
box::use(./mod/gpw)





all_prices <- readRDS("data/prices100.RDS")
#all_prices <- all_prices[, colnames(all_prices) != "ZAB"]
#all_prices <- all_prices[, !(colnames(all_prices) %in% c("SPR", "ARL", "DIA"))]






price_xts <- xts(all_prices[,-1], order.by = all_prices$Date)


min_history_days <- 250  # 1 rok notowań

for(col in colnames(price_xts)) {
  valid_data <- sum(!is.na(price_xts[, col]))
  
  if(valid_data < min_history_days) {
    # Usuń spółkę z obliczeń
    price_xts <- price_xts[, colnames(price_xts) != col]
  }
}


price_xts <- na.locf(price_xts)






emas <- xts()


for(cl in 1:ncol(price_xts)){
  
  #print(cl)
  
  
  ema1 <- SMA(price_xts[,cl], 2)
  
  ema2 <- SMA(price_xts[,cl], 200)
  
  
  #opóźnienie o 1 dzień, żeby nie było wyprzedzania danych
  #ema1 <- lag.xts(ema1, 1)
  
  #ema2 <- lag.xts(ema2, 1)
  
  
  
  is_trend <- (ema1 > ema2) #
  #is_trend <- ifelse(is.na(is_trend), 0, is_trend)
  is_trend <- ifelse(is_trend == TRUE, 1, 0)
  is_trend <- xts(is_trend, order.by = index(ema2))
  emas <- merge(emas, is_trend)
  
}




colnames(emas) <- colnames(price_xts)


positions <- emas





available_companies <- apply(positions, 1, function(row) {
  sum(!is.na(row))  # Liczba spółek z danymi w tym dniu
})


#spr
# all(diff(available_companies) >= 0)
# spadki <- which(diff(available_companies) < 0)
# length(spadki)  # Ile razy spada?


stable_start <- min(which(available_companies >= 50))

# 
positions <- positions[stable_start:nrow(positions), ]
available_companies <- available_companies[stable_start:length(available_companies)]


for(cl in 1:ncol(positions)){
  #print(cl)
  
  
  positions[, cl] <- ifelse(is.na(positions[, cl]), 0, positions[, cl])
  
 
}




#index
x_index <- positions |> rowSums()

index_trend <- xts(x_index, order.by = index(positions))

index_trend <- na.locf(index_trend)
index_trend <- na.omit(index_trend)

index_trend_perc <- index_trend / available_companies * 100
colnames(index_trend_perc) <- "index_trend_perc"


# WIG / WIG20 — tolerate any source failure. If the local stooq archive is
# missing and remote stooq is paywalled, the saved file simply omits that
# overlay — the indeksy/ chart still renders with the trend index alone.
W20 <- tryCatch(gpw$get_stooq_data("WIG20"), error = function(e) {
  message("WIG20 unavailable: ", conditionMessage(e)); NULL
})
WIG <- tryCatch(gpw$get_stooq_data("WIG"), error = function(e) {
  message("WIG unavailable: ", conditionMessage(e)); NULL
})

# Convert tibbles to xts with explicit column names so the indeksy/*.qmd
# pages can do `all_data$W20` and `all_data$WIG`.
tib_to_xts <- function(tib, col_name) {
  if (is.null(tib)) return(NULL)
  val_col <- setdiff(names(tib), "Date")[1]
  xts(setNames(data.frame(as.numeric(tib[[val_col]])), col_name),
      order.by = as.Date(tib$Date))
}
W20_xts <- tib_to_xts(W20, "W20")
WIG_xts <- tib_to_xts(WIG, "WIG")

merge_args <- list(index_trend_perc)
if (!is.null(W20_xts)) merge_args <- c(merge_args, list(W20_xts))
if (!is.null(WIG_xts)) merge_args <- c(merge_args, list(WIG_xts))
all_data <- do.call(merge, merge_args)

all_data <- na.locf(all_data)



all_data <- na.omit(all_data)

all_data |> saveRDS("data/index_trend.RDS")
