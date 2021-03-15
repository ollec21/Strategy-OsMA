/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_OsMA_Params_M15 : OsMAParams {
  Indi_OsMA_Params_M15() : OsMAParams(indi_osma_defaults, PERIOD_M15) {
    applied_price = (ENUM_APPLIED_PRICE)1;
    ema_fast_period = 8;
    ema_slow_period = 46;
    signal_period = 22;
    shift = 0;
  }
} indi_osma_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OsMA_Params_M15 : StgParams {
  // Struct constructor.
  Stg_OsMA_Params_M15() : StgParams(stg_osma_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)1;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_osma_m15;
