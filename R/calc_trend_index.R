
library(tidyverse)
library(xts)
library(zoo)
library(PerformanceAnalytics)
library(TTR)
library(janitor)
box::use(./mod/gpw)





all_prices <- readRDS("data/prices100.RDS")
#all_prices <- all_prices[, colnames(all_prices) != "ZAB"]
all_prices <- all_prices[, !(colnames(all_prices) %in% c("SPR", "ARL", "DIA"))]






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

price_xts <- price_xts[,-1]




emas <- xts()


for(cl in 1:ncol(price_xts)){
  
  #print(cl)
  
  
  ema1 <- SMA(price_xts[,cl], 2)
  
  ema2 <- SMA(price_xts[,cl], 200)
  
  
  #opóźnienie o 1 dzień, żeby nie było wyprzedzania danych
  #ema1 <- lag.xts(ema1, 1)
  
  #ema2 <- lag.xts(ema2, 1)
  
  
  
  is_trend <- (ema1 > ema2) #
  is_trend <- ifelse(is.na(is_trend), 0, is_trend)
  is_trend <- ifelse(is_trend == TRUE, 1, 0)
  is_trend <- xts(is_trend, order.by = index(ema2))
  emas <- merge(emas, is_trend)
  
}




colnames(emas) <- colnames(price_xts)


positions <- emas



for(cl in 1:ncol(positions)){
  #print(cl)
  
  
  positions[, cl] <- ifelse(is.na(positions[, cl]), 0, positions[, cl])
  
 
}




#index
x_index <- positions |> rowSums()

index_trend <- xts(x_index, order.by = index(positions))

index_trend <- na.locf(index_trend)
index_trend <- na.omit(index_trend)

index_streght <- index_trend / ncol(positions)


FW20 <- gpw$get_stooq_data("FW20")
WIG <- gpw$get_stooq_data("WIG")


all_data <- merge(index_streght, FW20, WIG)

all_data <- na.locf(all_data)

#zostawiam tylko ost. 250 dni
all_data <- all_data[(nrow(all_data)-250):nrow(all_data),]

all_data <- na.omit(all_data)

all_data |> saveRDS("data/index_trend.RDS")
