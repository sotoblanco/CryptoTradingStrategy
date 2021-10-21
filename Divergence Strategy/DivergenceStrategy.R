library(TTR)
library(tidyverse)

# futures instrument
instrument = "NQ"

path_file_update <- file.path(dirname("C:/Users/Pastor/Dropbox/Pastor/data/MarketProfile_data/.."))
data_main <- sprintf("%s_updated.csv", instrument)

df <- read.csv(file.path(path_file_update, data_main))
df$day_month <- as.Date(df$Date, format = "%Y-%m-%d")

df <- df %>% group_by(day_month) %>% summarise(Open = first(Open),
                                               High = max(High),
                                               Low = min(Low),
                                               Close = last(Close),
                                               Volume = sum(Volume))

#df$Date <- as.POSIXct(df$Date)

ggplot(df, aes(x = day_month, y = Close))+
  geom_line()

tp = 14

df$RSI <- RSI(df$Close, tp)
trend <- as.data.frame(aroon(df[,c("High", "Low")], n = tp))
df$AroonDown <- trend$aroonDn
df$AroonUp <- trend$aroonUp

df <- na.omit(df)

ggplot(tail(df,200), aes(x = day_month, y = AroonDown))+
  geom_line()

ggplot(tail(df,200), aes(x = day_month, y = AroonUp))+
  geom_line()

# compute the aroon value for the RSI
trendRSI <- as.data.frame(aroon(df[,c("RSI", "RSI")], n = tp))
df$AroonDownRSI <- trendRSI$aroonDn
df$AroonUpRSI <- trendRSI$aroonUp

#df <- na.omit(df)

# visualize the aroon values for the RSI
ggplot(tail(df, 200), aes(x = day_month, y = AroonDownRSI))+
  geom_line()

ggplot(tail(df, 200), aes(x = day_month, y = AroonUpRSI))+
  geom_line()

# calculate the spread or aroonup values for the price series and the RSI
df$UpSpread <- df$AroonUp - df$AroonUpRSI
df$DownSpread <- df$AroonDown - df$AroonDownRSI

# buy and sell signals
df$Sellsignal <- 0
df$Buysignal <- 0
t = 75


ggplot(tail(df, 200), aes(x = Date, y = UpSpread))+
  geom_line()+
  geom_hline(yintercept = t, color = "red")

# generate buy signals
df$Buysignal = ifelse(df$UpSpread > t, 1, df$Buysignal)

# generate sell signals
df$Sellsignal = ifelse(df$DownSpread > t, -1, df$Sellsignal)

# number of sell signals
sum(df$Sellsignal, na.rm = TRUE)

# number of buy signals
sum(df$Buysignal, na.rm = TRUE)

df$Signal <- df$Sellsignal + df$Buysignal

# creating the trade signal
# candle 1 closes: indicators are calculator and the signal is generated
# candle 2 opens: signal generated at the end of the previous candle is used to enter the trade
# candle 2 closes: indicators are calculated and new signal is generated
# candle 3 opens: the returns for the position taken at the open of candle 2 is calculated

df$TradeSignal = 0
df$TradeSignal = dplyr::lag(df$Signal, 1)

# calculate the returns
df$Return = (dplyr::lead(df$Open, 1) - df$Open)/df$Open
df$StrRet = df$TradeSignal * df$Return
df <- na.omit(df)
df$cumsum_ret <- cumsum(df$StrRet)


# plot the returns
ggplot(df, aes(x = day_month, y = cumsum_ret)) +
  geom_line()
