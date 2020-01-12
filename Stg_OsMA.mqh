//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2019, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements OSMA strategy based on the Moving Average of Oscillator indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_OSMA.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __OSMA_Parameters__ = "-- OsMA strategy params --";  // >>> OSMA <<<
INPUT int OSMA_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT ENUM_TRAIL_TYPE OSMA_TrailingStopMethod = 25;              // Trail stop method
INPUT ENUM_TRAIL_TYPE OSMA_TrailingProfitMethod = 1;             // Trail profit method
INPUT int OSMA_Period_Fast = 8;                                  // Period Fast
INPUT int OSMA_Period_Slow = 6;                                  // Period Slow
INPUT int OSMA_Period_Signal = 9;                                // Period for signal
INPUT ENUM_APPLIED_PRICE OSMA_Applied_Price = 4;                 // Applied Price
INPUT double OSMA_SignalOpenLevel = -0.2;                        // Signal open level
INPUT int OSMA1_SignalBaseMethod = 120;                          // Signal base method (0-
INPUT int OSMA1_OpenCondition1 = 0;                              // Open condition 1 (0-1023)
INPUT int OSMA1_OpenCondition2 = 0;                              // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT OSMA1_CloseCondition = C_OSMA_BUY_SELL;  // Close condition for M1
INPUT double OSMA_MaxSpread = 6.0;                               // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_OsMA_Params : Stg_Params {
  unsigned int OsMA_Period;
  ENUM_APPLIED_PRICE OsMA_Applied_Price;
  int OsMA_Shift;
  ENUM_TRAIL_TYPE OsMA_TrailingStopMethod;
  ENUM_TRAIL_TYPE OsMA_TrailingProfitMethod;
  double OsMA_SignalOpenLevel;
  long OsMA_SignalBaseMethod;
  long OsMA_SignalOpenMethod1;
  long OsMA_SignalOpenMethod2;
  double OsMA_SignalCloseLevel;
  ENUM_MARKET_EVENT OsMA_SignalCloseMethod1;
  ENUM_MARKET_EVENT OsMA_SignalCloseMethod2;
  double OsMA_MaxSpread;

  // Constructor: Set default param values.
  Stg_OsMA_Params()
      : OsMA_Period(::OsMA_Period),
        OsMA_Applied_Price(::OsMA_Applied_Price),
        OsMA_Shift(::OsMA_Shift),
        OsMA_TrailingStopMethod(::OsMA_TrailingStopMethod),
        OsMA_TrailingProfitMethod(::OsMA_TrailingProfitMethod),
        OsMA_SignalOpenLevel(::OsMA_SignalOpenLevel),
        OsMA_SignalBaseMethod(::OsMA_SignalBaseMethod),
        OsMA_SignalOpenMethod1(::OsMA_SignalOpenMethod1),
        OsMA_SignalOpenMethod2(::OsMA_SignalOpenMethod2),
        OsMA_SignalCloseLevel(::OsMA_SignalCloseLevel),
        OsMA_SignalCloseMethod1(::OsMA_SignalCloseMethod1),
        OsMA_SignalCloseMethod2(::OsMA_SignalCloseMethod2),
        OsMA_MaxSpread(::OsMA_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_OSMA : public Strategy {
 public:
  Stg_OSMA(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_OsMA *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_OsMA_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_OsMA_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_OsMA_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_OsMA_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_OsMA_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_OsMA_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_OsMA_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    OsMA_Params adx_params(_params.OsMA_Period, _params.OsMA_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_OsMA);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_OsMA(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.OsMA_SignalBaseMethod, _params.OsMA_SignalOpenMethod1, _params.OsMA_SignalOpenMethod2,
                       _params.OsMA_SignalCloseMethod1, _params.OsMA_SignalCloseMethod2, _params.OsMA_SignalOpenLevel,
                       _params.OsMA_SignalCloseLevel);
    sparams.SetStops(_params.OsMA_TrailingProfitMethod, _params.OsMA_TrailingStopMethod);
    sparams.SetMaxSpread(_params.OsMA_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_OsMA(sparams, "OsMA");
    return _strat;
  }

  /**
   * Check if OSMA indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double osma_0 = ((Indi_OsMA *)this.Data()).GetValue(0);
    double osma_1 = ((Indi_OsMA *)this.Data()).GetValue(1);
    double osma_2 = ((Indi_OsMA *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      /*
        //22. Moving Average of Oscillator (MACD histogram) (1)
        //Buy: histogram is below zero and changes falling direction into rising (5 columns are taken)
        //Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken)
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f22=1;}
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f22=-1;}
      */

      /*
        //23. Moving Average of Oscillator (MACD histogram) (2)
        //To use the indicator it should be correlated with another trend indicator
        //Flag 23 is 1, when MACD histogram recommends to buy (i.e. histogram is sloping upwards)
        //Flag 23 is -1, when MACD histogram recommends to sell (i.e. histogram is sloping downwards)
        //3 columns are taken for calculation
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f23=1;}
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f23=-1;}
      */
      case ORDER_TYPE_BUY:
        break;
      case ORDER_TYPE_SELL:
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};