//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements OsMA strategy based on the Moving Average of Oscillator indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_OsMA.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __OsMA_Parameters__ = "-- OsMA strategy params --";  // >>> OsMA <<<
INPUT int OsMA_Period_Fast = 8;                                   // Period Fast
INPUT int OsMA_Period_Slow = 6;                                   // Period Slow
INPUT int OsMA_Period_Signal = 9;                                 // Period for signal
INPUT ENUM_APPLIED_PRICE OsMA_Applied_Price = 4;                  // Applied Price
INPUT int OsMA_Shift = 0;                                         // Shift
INPUT int OsMA_SignalOpenMethod = 120;                            // Signal open method (0-
INPUT double OsMA_SignalOpenLevel = -0.2;                         // Signal open level
INPUT int OsMA_SignalOpenFilterMethod = 0;                        // Signal open filter method
INPUT int OsMA_SignalOpenBoostMethod = 0;                         // Signal open boost method
INPUT int OsMA_SignalCloseMethod = 120;                           // Signal close method (0-
INPUT double OsMA_SignalCloseLevel = -0.2;                        // Signal close level
INPUT int OsMA_PriceLimitMethod = 0;                              // Price limit method
INPUT double OsMA_PriceLimitLevel = 0;                            // Price limit level
INPUT double OsMA_MaxSpread = 6.0;                                // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_OsMA_Params : StgParams {
  int OsMA_Period_Fast;
  int OsMA_Period_Slow;
  int OsMA_Period_Signal;
  ENUM_APPLIED_PRICE OsMA_Applied_Price;
  int OsMA_Shift;
  int OsMA_SignalOpenMethod;
  double OsMA_SignalOpenLevel;
  int OsMA_SignalOpenFilterMethod;
  int OsMA_SignalOpenBoostMethod;
  int OsMA_SignalCloseMethod;
  double OsMA_SignalCloseLevel;
  int OsMA_PriceLimitMethod;
  double OsMA_PriceLimitLevel;
  double OsMA_MaxSpread;

  // Constructor: Set default param values.
  Stg_OsMA_Params()
      : OsMA_Period_Fast(::OsMA_Period_Fast),
        OsMA_Period_Slow(::OsMA_Period_Slow),
        OsMA_Period_Signal(::OsMA_Period_Signal),
        OsMA_Applied_Price(::OsMA_Applied_Price),
        OsMA_Shift(::OsMA_Shift),
        OsMA_SignalOpenMethod(::OsMA_SignalOpenMethod),
        OsMA_SignalOpenLevel(::OsMA_SignalOpenLevel),
        OsMA_SignalOpenFilterMethod(::OsMA_SignalOpenFilterMethod),
        OsMA_SignalOpenBoostMethod(::OsMA_SignalOpenBoostMethod),
        OsMA_SignalCloseMethod(::OsMA_SignalCloseMethod),
        OsMA_SignalCloseLevel(::OsMA_SignalCloseLevel),
        OsMA_PriceLimitMethod(::OsMA_PriceLimitMethod),
        OsMA_PriceLimitLevel(::OsMA_PriceLimitLevel),
        OsMA_MaxSpread(::OsMA_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_OsMA : public Strategy {
 public:
  Stg_OsMA(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_OsMA *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_OsMA_Params _params;
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_OsMA_Params>(_params, _tf, stg_osma_m1, stg_osma_m5, stg_osma_m15, stg_osma_m30, stg_osma_h1,
                                     stg_osma_h4, stg_osma_h4);
    }
    // Initialize strategy parameters.
    OsMAParams osma_params(_params.OsMA_Period_Fast, _params.OsMA_Period_Slow, _params.OsMA_Period_Signal,
                            _params.OsMA_Applied_Price);
    osma_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_OsMA(osma_params), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.OsMA_SignalOpenMethod, _params.OsMA_SignalOpenLevel, _params.OsMA_SignalCloseMethod,
                       _params.OsMA_SignalOpenFilterMethod, _params.OsMA_SignalOpenBoostMethod,
                       _params.OsMA_SignalCloseLevel);
    sparams.SetPriceLimits(_params.OsMA_PriceLimitMethod, _params.OsMA_PriceLimitLevel);
    sparams.SetMaxSpread(_params.OsMA_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_OsMA(sparams, "OsMA");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    Indi_OsMA *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: histogram is below zero and changes falling direction into rising (5 columns are taken).
          _result = _indi[CURR].value[0] < 0 && _indi[CURR].value[0] > _indi[PREV].value[0];
          if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] < _indi[PPREV].value[0]; // ... 2 consecutive columns are red.
          if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] < _indi[3].value[0]; // ... 3 consecutive columns are red.
          if (METHOD(_method, 2)) _result &= _indi[3].value[0] < _indi[4].value[0]; // ... 4 consecutive columns are red.
          if (METHOD(_method, 3)) _result &= _indi[PREV].value[0] > _indi[PPREV].value[0]; // ... 2 consecutive columns are green.
          if (METHOD(_method, 4)) _result &= _indi[PPREV].value[0] > _indi[3].value[0]; // ... 3 consecutive columns are green.
          if (METHOD(_method, 5)) _result &= _indi[3].value[0] < _indi[4].value[0]; // ... 4 consecutive columns are green.
          break;
        case ORDER_TYPE_SELL:
          // Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken).
          _result = _indi[CURR].value[0] > 0 && _indi[CURR].value[0] < _indi[PREV].value[0];
          if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] < _indi[PPREV].value[0]; // ... 2 consecutive columns are red.
          if (METHOD(_method, 1)) _result &= _indi[PPREV].value[0] < _indi[3].value[0]; // ... 3 consecutive columns are red.
          if (METHOD(_method, 2)) _result &= _indi[3].value[0] < _indi[4].value[0]; // ... 4 consecutive columns are red.
          if (METHOD(_method, 3)) _result &= _indi[PREV].value[0] > _indi[PPREV].value[0]; // ... 2 consecutive columns are green.
          if (METHOD(_method, 4)) _result &= _indi[PPREV].value[0] > _indi[3].value[0]; // ... 3 consecutive columns are green.
          if (METHOD(_method, 5)) _result &= _indi[3].value[0] < _indi[4].value[0]; // ... 4 consecutive columns are green.
          break;
      }
    }
    return _result;
  }

  /**
   * Check strategy's opening signal additional filter.
   */
  bool SignalOpenFilter(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = true;
    if (_method != 0) {
      // if (METHOD(_method, 0)) _result &= Trade().IsTrend(_cmd);
      // if (METHOD(_method, 1)) _result &= Trade().IsPivot(_cmd);
      // if (METHOD(_method, 2)) _result &= Trade().IsPeakHours(_cmd);
      // if (METHOD(_method, 3)) _result &= Trade().IsRoundNumber(_cmd);
      // if (METHOD(_method, 4)) _result &= Trade().IsHedging(_cmd);
      // if (METHOD(_method, 5)) _result &= Trade().IsPeakBar(_cmd);
    }
    return _result;
  }

  /**
   * Gets strategy's lot size boost (when enabled).
   */
  double SignalOpenBoost(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = 1.0;
    if (_method != 0) {
      // if (METHOD(_method, 0)) if (Trade().IsTrend(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 1)) if (Trade().IsPivot(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 2)) if (Trade().IsPeakHours(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 3)) if (Trade().IsRoundNumber(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 4)) if (Trade().IsHedging(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 5)) if (Trade().IsPeakBar(_cmd)) _result *= 1.1;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, double _level = 0.0) {
    Indi_OsMA *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count = (int) _level * (int) _indi.GetEmaFastPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count)) : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 1: {
          int _bar_count = (int) _level * (int) _indi.GetEmaSlowPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count)) : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 2: {
          int _bar_count = (int) _level * (int) _indi.GetSignalPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count)) : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 3:
          _result = (_direction > 0 ? fmax(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL]) : fmin(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL]));
          break;
      }
      _result += _trail * _direction;
    }
    return _result;
  }
};
