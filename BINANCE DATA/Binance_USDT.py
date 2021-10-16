# -*- coding: utf-8 -*-
"""
Created on Mon Oct 11 20:59:16 2021

@author: Pastor
"""

import requests                    # for "get" request to API
import json                        # parse json into a list
import pandas as pd                # working with data frames
import datetime as dt              # working with dates
import matplotlib.pyplot as plt    # plot data
import qgrid                       # display dataframe in notebooks
import os
import time
from threading import Thread

BASE_URL = 'https://api.binance.com'

symbols = []

resp = requests.get(BASE_URL + '/api/v1/ticker/allBookTickers')
tickers_list = json.loads(resp.content)
for ticker in tickers_list:
    if str(ticker['symbol'])[-4:] == 'USDT':
        symbols.append(ticker['symbol'])



def get_binance_bars(symbol, interval, startTime, endTime):
 
    url = "https://api.binance.com/api/v3/klines"
 
    startTime = str(int(startTime.timestamp() * 1000))
    endTime = str(int(endTime.timestamp() * 1000))
    limit = '1000'
 
    req_params = {"symbol" : symbol, 'interval' : interval, 'startTime' : startTime, 'endTime' : endTime, 'limit' : limit}
 
    df = pd.DataFrame(json.loads(requests.get(url, params = req_params).text))
 
    if (len(df.index) == 0):
        return None
     
    df = df.iloc[:, 0:6]
    df.columns = ['datetime', 'open', 'high', 'low', 'close', 'volume']
 
    df.open      = df.open.astype("float")
    df.high      = df.high.astype("float")
    df.low       = df.low.astype("float")
    df.close     = df.close.astype("float")
    df.volume    = df.volume.astype("float")
    
    df['adj_close'] = df['close']
     
    df.index = [dt.datetime.fromtimestamp(x / 1000.0) for x in df.datetime]
 
    return df

timeframe = '1d'

for i in symbols:
    df_list = []
    last_datetime = dt.datetime(2021, 1, 1) # year, month, day
    while True:
        print(last_datetime)
        new_df = get_binance_bars(i, timeframe, last_datetime, dt.datetime.now())
        if new_df is None:
            break
        df_list.append(new_df)
        last_datetime = max(new_df.index) + dt.timedelta(1, 0)
        df = pd.concat(df_list)
        df.reset_index(level=0, inplace=True)
        df.columns = ['']

        
        file_dir = r'C:\Users\Pastor\Dropbox\Pastor\data\binance_data_feather\{0}.feather'.format(i)
        
        df.to_feather(file_dir)

        
        #df.to_csv(file_dir, index = True, header=True)
        




