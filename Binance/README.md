# Binance

We get all symbols of any available pair using the Binance API

## Instructions

The first time we run this code it takes a significant amount of time given that it is required all the historical data for every instrument. After we run the script, download and store the data the script only will download the updated file, read the old file and store as a single csv file for each pair. 

## Global variables
Using this script you will be able to change the global variables:

 * __pair__: you want to trade (USDT, BUSD, BTC, ETH...)
 
 * __timeframe__: Timeframe that could be daily (1d), hourly (1h), minute (1m) and any variation of each timeframe.
 
 * __file_out__: last name of the folder you want to store your data
