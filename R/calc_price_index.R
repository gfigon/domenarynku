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







available_companies <- apply(price_xts, 1, function(row) {
  sum(!is.na(row))  # Liczba spółek z danymi w tym dniu
})


#spr
# all(diff(available_companies) >= 0)
# spadki <- which(diff(available_companies) < 0)
# length(spadki)  # Ile razy spada?


stable_start <- min(which(available_companies >= 50))

# 
prices_filtered <- price_xts[stable_start:nrow(price_xts), ]
available_companies <- available_companies[stable_start:length(available_companies)]


# for(cl in 1:ncol(prices_filtered)){
#   #print(cl)
#   
#   
#   prices_filtered[, cl] <- ifelse(is.na(prices_filtered[, cl]), 0, prices_filtered[, cl])
#   
#   
# }




#index
price_returns <- diff(log(prices_filtered))

x_index <-  apply(price_returns, 1, mean, na.rm = TRUE)

x_index[1] <- 0 

index_rets <- xts(x_index, order.by = index(price_returns))

index_rets_csum <- cumsum(index_rets)

index_rets_norm <- 100* exp(index_rets_csum)

index_rets_norm <- na.locf(index_rets_norm)
index_rets_norm <- na.omit(index_rets_norm)
colnames(index_rets_norm) <- "unweighted_index"



# WIG / WIG20 — tolerate any source failure. If the local stooq archive is
# missing and remote stooq is paywalled, the saved file simply omits that
# overlay — the indeksy/ chart still renders with the price index alone.
W20 <- tryCatch(gpw$get_stooq_data("WIG20"), error = function(e) {
  message("WIG20 unavailable: ", conditionMessage(e)); NULL
})
WIG <- tryCatch(gpw$get_stooq_data("WIG"), error = function(e) {
  message("WIG unavailable: ", conditionMessage(e)); NULL
})

tib_to_xts <- function(tib, col_name) {
  if (is.null(tib)) return(NULL)
  val_col <- setdiff(names(tib), "Date")[1]
  xts(setNames(data.frame(as.numeric(tib[[val_col]])), col_name),
      order.by = as.Date(tib$Date))
}
W20_xts <- tib_to_xts(W20, "W20")
WIG_xts <- tib_to_xts(WIG, "WIG")

merge_args <- list(index_rets_norm)
if (!is.null(W20_xts)) merge_args <- c(merge_args, list(W20_xts))
if (!is.null(WIG_xts)) merge_args <- c(merge_args, list(WIG_xts))
all_data <- do.call(merge, merge_args)

all_data <- na.locf(all_data)



all_data <- na.omit(all_data)

all_data |> saveRDS("data/index_unweighted.RDS")