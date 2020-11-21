/**
 * @file
 * Implements OsMA strategy based on the Moving Average of Oscillator indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_OsMA.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float OsMA_LotSize = 0;               // Lot size
INPUT int OsMA_SignalOpenMethod = 120;      // Signal open method (0-
INPUT float OsMA_SignalOpenLevel = -0.2f;   // Signal open level
INPUT int OsMA_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int OsMA_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int OsMA_SignalCloseMethod = 120;     // Signal close method (0-
INPUT float OsMA_SignalCloseLevel = -0.2f;  // Signal close level
INPUT int OsMA_PriceLimitMethod = 0;        // Price limit method
INPUT float OsMA_PriceLimitLevel = 0;       // Price limit level
INPUT int OsMA_TickFilterMethod = 0;        // Tick filter method
INPUT float OsMA_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int OsMA_Shift = 0;                   // Shift
INPUT string __OsMA_Indi_OsMA_Parameters__ =
    "-- OsMA strategy: OsMA indicator params --";      // >>> OsMA strategy: OsMA indicator <<<
INPUT int Indi_OsMA_Period_Fast = 8;                   // Period Fast
INPUT int Indi_OsMA_Period_Slow = 6;                   // Period Slow
INPUT int Indi_OsMA_Period_Signal = 9;                 // Period for signal
INPUT ENUM_APPLIED_PRICE Indi_OsMA_Applied_Price = 4;  // Applied Price

// Structs.

// Defines struct with default user indicator values.
struct Indi_OsMA_Params_Defaults : OsMAParams {
  Indi_OsMA_Params_Defaults()
      : OsMAParams(::Indi_OsMA_Period_Fast, ::Indi_OsMA_Period_Slow, ::Indi_OsMA_Period_Signal,
                   ::Indi_OsMA_Applied_Price) {}
} indi_osma_defaults;

// Defines struct to store indicator parameter values.
struct Indi_OsMA_Params : public OsMAParams {
  // Struct constructors.
  void Indi_OsMA_Params(OsMAParams &_params, ENUM_TIMEFRAMES _tf) : OsMAParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_OsMA_Params_Defaults : StgParams {
  Stg_OsMA_Params_Defaults()
      : StgParams(::OsMA_SignalOpenMethod, ::OsMA_SignalOpenFilterMethod, ::OsMA_SignalOpenLevel,
                  ::OsMA_SignalOpenBoostMethod, ::OsMA_SignalCloseMethod, ::OsMA_SignalCloseLevel,
                  ::OsMA_PriceLimitMethod, ::OsMA_PriceLimitLevel, ::OsMA_TickFilterMethod, ::OsMA_MaxSpread,
                  ::OsMA_Shift) {}
} stg_osma_defaults;

// Struct to define strategy parameters to override.
struct Stg_OsMA_Params : StgParams {
  Indi_OsMA_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_OsMA_Params(Indi_OsMA_Params &_iparams, StgParams &_sparams)
      : iparams(indi_osma_defaults, _iparams.tf), sparams(stg_osma_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_OsMA : public Strategy {
 public:
  Stg_OsMA(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_OsMA *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_OsMA_Params _indi_params(indi_osma_defaults, _tf);
    StgParams _stg_params(stg_osma_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_OsMA_Params>(_indi_params, _tf, indi_osma_m1, indi_osma_m5, indi_osma_m15, indi_osma_m30,
                                      indi_osma_h1, indi_osma_h4, indi_osma_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_osma_m1, stg_osma_m5, stg_osma_m15, stg_osma_m30, stg_osma_h1,
                               stg_osma_h4, stg_osma_h8);
    }
    // Initialize indicator.
    OsMAParams osma_params(_indi_params);
    _stg_params.SetIndicator(new Indi_OsMA(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_OsMA(_stg_params, "OsMA");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_OsMA *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: histogram is below zero and changes falling direction into rising (5 columns are taken).
          _result = _indi[CURR].value[0] < 0 && _indi[CURR].value[0] > _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
        case ORDER_TYPE_SELL:
          // Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken).
          _result = _indi[CURR].value[0] > 0 && _indi[CURR].value[0] < _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_OsMA *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count0 = (int)_level * (int)_indi.GetEmaFastPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count0));
          break;
        }
        case 1: {
          int _bar_count1 = (int)_level * (int)_indi.GetEmaSlowPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count1));
          break;
        }
        case 2: {
          int _bar_count2 = (int)_level * (int)_indi.GetSignalPeriod();
          _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count2))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count2));
          break;
        }
        case 3:
          _result = (_direction > 0 ? fmax(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL])
                                    : fmin(_indi[PPREV].value[LINE_MAIN], _indi[PPREV].value[LINE_SIGNAL]));
          break;
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
