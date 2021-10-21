library(TTR)
library(tidyverse)

options(scipen = 999) # this allow to not use scientific notation for the output

pair = "USDT"
# Read the weekly file
setwd(sprintf("C:/Users/Pastor/Dropbox/Pastor/data/binance_data_%s", pair))
filelist = list.files(pattern = ".*.csv")
crypto <- lapply(filelist, FUN=read.csv)
names(crypto) <- filelist

tp <- 14
t = 75


crypto <- crypto[sapply(crypto, nrow) > 100]

for (i in 1:length(crypto)) {
  crypto[[i]]$crypto_name <- names(crypto)[i]
  
  crypto[[i]]$RSI <- RSI(crypto[[i]]$Close, tp)
  trend <- as.data.frame(aroon(crypto[[i]][,c("High", "Low")], n = tp))
  crypto[[i]]$AroonDown <- trend$aroonDn
  crypto[[i]]$AroonUp <- trend$aroonUp
  crypto[[i]] <- na.omit(crypto[[i]])
  # compute the aroon value for the RSI
  trendRSI <- as.data.frame(aroon(crypto[[i]][,c("RSI", "RSI")], n = tp))
  crypto[[i]]$AroonDownRSI <- trendRSI$aroonDn
  crypto[[i]]$AroonUpRSI <- trendRSI$aroonUp
  
  # calculate the spread or aroonup values for the price series and the RSI
  crypto[[i]]$UpSpread <- crypto[[i]]$AroonUp - crypto[[i]]$AroonUpRSI
  crypto[[i]]$DownSpread <- crypto[[i]]$AroonDown - crypto[[i]]$AroonDownRSI
  
  # buy and sell signals
  crypto[[i]]$Sellsignal <- 0
  crypto[[i]]$Buysignal <- 0
  
  # generate buy signals
  crypto[[i]]$Buysignal = ifelse(crypto[[i]]$UpSpread > t, 1, crypto[[i]]$Buysignal)
  
  # generate sell signals
  crypto[[i]]$Sellsignal = ifelse(crypto[[i]]$DownSpread > t, -1, crypto[[i]]$Sellsignal)
  
  crypto[[i]]$Signal <- crypto[[i]]$Sellsignal + crypto[[i]]$Buysignal
  
  # creating the trade signal
  # candle 1 closes: indicators are calculator and the signal is generated
  # candle 2 opens: signal generated at the end of the previous candle is used to enter the trade
  # candle 2 closes: indicators are calculated and new signal is generated
  # candle 3 opens: the returns for the position taken at the open of candle 2 is calculated
  
  crypto[[i]]$TradeSignal = 0
  crypto[[i]]$TradeSignal = dplyr::lag(crypto[[i]]$Signal, 1)
  
  # calculate the returns
  crypto[[i]]$Return = (dplyr::lead(crypto[[i]]$Open, 1) - crypto[[i]]$Open)/crypto[[i]]$Open
  crypto[[i]]$StrRet = crypto[[i]]$TradeSignal * crypto[[i]]$Return
  crypto[[i]] <- na.omit(crypto[[i]])
  crypto[[i]]$cumsum_ret <- round(cumsum(crypto[[i]]$StrRet),4)

}

crypto_list <- crypto %>% bind_rows %>% 
  select(Date, crypto_name, Close, UpSpread, DownSpread, RSI, AroonDown, AroonUp, AroonDownRSI, AroonUpRSI,
         Buysignal, Sellsignal, Signal, TradeSignal, cumsum_ret)

len_del = nchar(pair) + 5

crypto_list$crypto_name <- str_sub(crypto_list$crypto_name, end = -len_del)
crypto_list$Date <- str_sub(crypto_list$Date, end = -10)

crypto_list_last <- subset(crypto_list, Date == last(crypto_list$Date))

crypto_list_last <- crypto_list_last[with(crypto_list_last, order(-UpSpread,-cumsum_ret)),]


setwd("C:/Users/Pastor/Dropbox/Pastor/DivergenceStrategy")
write.csv(crypto_list_last, sprintf("DivergenceStrategy_%s.csv", pair), row.names = FALSE)


