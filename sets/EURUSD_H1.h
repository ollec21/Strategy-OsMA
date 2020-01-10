//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OsMA_EURUSD_H1_Params : Stg_OsMA_Params {
  Stg_OsMA_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    OsMA_Period = 2;
    OsMA_Applied_Price = 3;
    OsMA_Shift = 0;
    OsMA_TrailingStopMethod = 6;
    OsMA_TrailingProfitMethod = 11;
    OsMA_SignalOpenLevel = 36;
    OsMA_SignalBaseMethod = 0;
    OsMA_SignalOpenMethod1 = 195;
    OsMA_SignalOpenMethod2 = 0;
    OsMA_SignalCloseLevel = 36;
    OsMA_SignalCloseMethod1 = 1;
    OsMA_SignalCloseMethod2 = 0;
    OsMA_MaxSpread = 6;
  }
};
