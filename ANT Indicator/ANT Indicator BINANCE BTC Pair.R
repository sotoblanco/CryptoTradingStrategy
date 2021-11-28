library(tidyverse)
library(lubridate)
library(quantmod)
library(rlist)
library(tseries)
library(timeSeries)
library(forecast)
library(xts)
library(tidyquant)
library(stringr)

options(scipen = 999) # this allow to not use scientific notation for the output

pair = "USDT"
timeframe = "1d"
# Read the weekly file
setwd(sprintf("D:/Dropbox/Pastor/data/binance_data_%s", timeframe))
filelist = list.files(pattern = ".*.csv")
crypto <- lapply(filelist, FUN=read.csv)
names(crypto) <- filelist

n <- 15


crypto <- crypto[sapply(crypto, nrow) > 100]


for (i in 1:length(crypto)) {
  crypto[[i]]$crypto_name <- names(crypto)[i]
  
  #momentum is up at least 12 out of 15 days
  crypto[[i]]$ret <- with(crypto[[i]], log(Close/dplyr::lag(Close)))
  crypto[[i]] <- na.omit(crypto[[i]])
  crypto[[i]]$mom <- ifelse(crypto[[i]]$ret > 0, 1, 0)
  cs <- cumsum(crypto[[i]]$mom)
  crypto[[i]]$momentum_total <- c(rep_len(NA, n - 1), tail(cs, -(n - 1)) - c(0, head(cs, -n)))
  crypto[[i]]$momentum <- ifelse(crypto[[i]]$momentum_total > 11, 1,0)
  
  ## Price: The price is up at least 20% over the past 15 days
  crypto[[i]][["runmeanPrice"]] <- runMean(crypto[[i]][["Close"]], 15, FALSE)
  crypto[[i]]$price_mom <- round((crypto[[i]]$Close-crypto[[i]]$runmeanPrice)/(crypto[[i]]$runmeanPrice)*100,2)
  crypto[[i]]$pprice <- ifelse(crypto[[i]]$price_mom >= 20, 1, 0)
  
  ## The volume has increase over the past 15 days by 20% 
  crypto[[i]][["runmeanVol"]] <- round(runMean(crypto[[i]]["Volume"], 15, FALSE),2)
  crypto[[i]][["runmeanVol50"]] <- round(runMean(crypto[[i]]["Volume"], 50, FALSE),2)
  crypto[[i]]$volume_mon <- round(((crypto[[i]]$runmeanVol-crypto[[i]]$runmeanVol50)/(crypto[[i]]$runmeanVol50))*100,2)
  crypto[[i]]$vol <- ifelse(crypto[[i]]$volume_mon >= 20, 1, 0)
  
  
  # Ant indicator
  crypto[[i]]$gray <- ifelse(crypto[[i]]$momentum_total >= 12, 1, 0) # gray price is up by 20%
  crypto[[i]]$blue <- ifelse(crypto[[i]]$momentum == 1 & crypto[[i]]$pprice == 1, 1, 0) # price is up and is at least 20% up
  crypto[[i]]$yellow <- ifelse(crypto[[i]]$momentum == 1 & crypto[[i]]$vol==1, 1, 0) 
  crypto[[i]]$green <- ifelse(crypto[[i]]$momentum == 1 & crypto[[i]]$pprice == 1 & crypto[[i]]$vol == 1, 1, 0)
  
  
  crypto[[i]] <- na.omit(crypto[[i]])
  
}

crypto_list <- crypto %>% bind_rows %>% 
  select(Date, crypto_name ,momentum_total, price_mom, volume_mon, gray, blue, yellow, green, Close,
         runmeanPrice, runmeanVol, runmeanVol50)

crypto_list <- rename(crypto_list, day_month = Date, Close = Close)

len_del = nchar(pair) + 5

crypto_list$crypto_name <- str_sub(crypto_list$crypto_name, end = -len_del)
crypto_list$day_month <- str_sub(crypto_list$day_month, end = -10)

crypto_list_last <- subset(crypto_list, day_month == last(crypto_list$day_month))

ant_indicator <- crypto_list %>% group_by(crypto_name) %>% summarise(day_month = last(day_month),
                                                                     momentum_total = last(momentum_total), # greater than 12
                                                                     price_mom = round(last(price_mom),2), # price up 20%
                                                                     volume_mon = round(last(volume_mon),2), # volume 20 to 25%
                                                                     gray =  last(gray),
                                                                     blue = last(blue), 
                                                                     yellow = last(yellow),
                                                                     green = last(green),
                                                                     Close = last(Close))

ant_indicator$day_month <- as.Date(ant_indicator$day_month)
ant_indicator <- ant_indicator[with(ant_indicator, order(day_month)),]

ant_indicator <- ant_indicator[!ant_indicator$day_month != last(ant_indicator$day_month),]

ant_indicator <- ant_indicator[with(ant_indicator, order(-momentum_total, -volume_mon, -price_mom)),]

setwd("D:/Dropbox/Pastor/Power BI/Data")
write.csv(crypto_list, sprintf("crypto_list_%s.csv", pair), row.names = FALSE)

setwd("D:/Dropbox/Pastor/ANT Indicator")
write.csv(ant_indicator, sprintf("ant_selection_%s.csv", pair), row.names = FALSE)

