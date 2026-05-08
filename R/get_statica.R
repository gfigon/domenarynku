library(xts)
library(tidyverse)



get_statica <- function(){
  
  #LIVE DATA STATICA
  #FW20 <- read_csv("C:/Users/grzeg/Documents/Notowania 5/Pliki CSV/GPW/FW20.csv", col_types = cols(`X1` = col_date(format = "%y%m%d"),
  #                                                                                                 `X2` = col_time(format = "%H%M%S")), col_names = FALSE, lazy = FALSE)#, skip = 50000
  
  FW20 <- read_csv("data/FW20.csv", col_types = cols(`X1` = col_date(format = "%y%m%d"),
                                                `X2` = col_time(format = "%H%M%S")), col_names = FALSE, lazy = FALSE)#, skip = 50000
  
  
  colnames(FW20) <- c("Date", "Time", "Price", "Tr", "LOP")
  
  FW20 <- FW20 %>% mutate(Date = ymd_hms(paste0(Date, Time)))
  FW20 <- FW20 %>% select(-Time)
  
  
  fw_xts <- xts(FW20[,2:4], order.by = FW20$Date)
  
  
  tr <- period.apply(fw_xts$Tr, endpoints(fw_xts$Tr, "hours"), sum)
  LOP <- period.apply(fw_xts$LOP, endpoints(fw_xts$LOP, "hours"), mean)
  
  
  
  fw_price <- to.hourly(fw_xts$Price, indexAt = "startof")
  
  
  fw_price$tr <- as.numeric(tr)
  fw_price$LOP <- as.numeric(LOP)
  
  
  colnames(fw_price) <- c("Open", "High", "Low", "Close", "Tr", "LOP")
  
  fw_price
  
}


tickerS <- get_statica()

last_session <- tickerS["2024-10-22"]
this_session <- tickerS["2024-10-23"]


