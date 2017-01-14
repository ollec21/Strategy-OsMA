//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of OsMA Strategy based on the Moving Average of Oscillator indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iOsMA
 * - https://www.mql5.com/en/docs/indicators/iOsMA
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

#define OSMA_VALUES  5

// User inputs.
#ifdef __input__ input #endif string __OSMA_Parameters__ = "-- Settings for the Moving Average of Oscillator indicator --"; // >>> OSMA <<<
#ifdef __input__ input #endif int OSMA_Period_Fast = 11; // Period Fast
#ifdef __input__ input #endif int OSMA_Period_Slow = 42; // Period Slow
#ifdef __input__ input #endif int OSMA_Period_Signal = 9; // Period for signal
#ifdef __input__ input #endif double OSMA_Period_Ratio = 1.0; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif ENUM_APPLIED_PRICE OSMA_Applied_Price = 0; // Applied Price
#ifdef __input__ input #endif double OSMA_SignalLevel = 1.20000000; // Signal level
#ifdef __input__ input #endif int OSMA_SignalMethod = 15; // Signal method for M1 (0-

//+------------------------------------------------------------------+
//|   TMovingAverage                                                 |
//+------------------------------------------------------------------+
struct OsMAParams
  {
   int               handles[TFS];
   string            symbol;
   uint              fast_period;
   uint              slow_period;
   uint              signal_period;
   ENUM_APPLIED_PRICE price;
   uint              shift;
  };
//+------------------------------------------------------------------+
//|   CMovingTrade                                                   |
//+------------------------------------------------------------------+
class OsMA: public Strategy {

private:
   OsMAParams        m_params;
   double            m_val[TFS][OSMA_VALUES];
   int               m_last_error;

   //+------------------------------------------------------------------+
   int               TimeframeToIndex(ENUM_TIMEFRAMES _tf)
     {
      if(_tf==0 || _tf==PERIOD_CURRENT)
         _tf=(ENUM_TIMEFRAMES)_Period;
      int total=ArraySize(tf);
      for(int i=0;i<total;i++)
        {
         if(tf[i]==_tf)
            return(i);
        }
      return(0);
     }
/*
    // Calculates the Moving Average of Oscillator indicator.
      for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
        osma[index][i] = iOsMA(symbol, tf, OSMA_Period_Fast, OSMA_Period_Slow, OSMA_Period_Signal, OSMA_Applied_Price, i);
      }
      success = (bool)osma[index][CURR];

  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_OSMA, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_OSMA, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_OSMA, tf, 0.0);
    switch (cmd) {
      /*
        //22. Moving Average of Oscillator (MACD histogram) (1)
        //Buy: histogram is below zero and changes falling direction into rising (5 columns are taken)
        //Sell: histogram is above zero and changes its rising direction into falling (5 columns are taken)
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)<0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f22=1;}
        if(iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0)>0&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,4)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,3)<=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,2)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)&&iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,1)>=iOsMA(NULL,pimacd,fastpimacd,slowpimacd,signalpimacd,PRICE_CLOSE,0))
        {f22=-1;}
      /

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
      /
      case OP_BUY:
        break;
      case OP_SELL:
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
*/

   //+------------------------------------------------------------------+
   bool              Update(const ENUM_TIMEFRAMES _tf=PERIOD_CURRENT)
     {
      int index=TimeframeToIndex(_tf);

#ifdef __MQL4__

      for(int k=0;k<OSMA_VALUES;k++)
        {
         m_val[index][k]=iOsMA(NULL,
                               _tf,
                               m_params.fast_period,
                               m_params.slow_period,
                               m_params.signal_period,
                               m_params.price,
                               k+m_params.shift);
        }
      return(true);
#endif

#ifdef __MQL5__
      double MaArray[];

      if(CopyBuffer(m_params.handles[index],0,m_params.shift,OSMA_VALUES,MaArray)!=OSMA_VALUES)
         return(false);
      m_val[index][CUR]=MaArray[2];
      m_val[index][PREV]=MaArray[1];
      m_val[index][FAR]=MaArray[0];

      return(true);
#endif

      return(false);
     }
public:
   //+------------------------------------------------------------------+
                     CMacdTrade()

     {
      m_last_error=0;
      ArrayInitialize(m_params.handles,INVALID_HANDLE);
      m_params.fast_period = 12;
      m_params.slow_period = 26;
      m_params.signal_period=9;
      m_params.price=PRICE_CLOSE;
     }
   //+------------------------------------------------------------------+
   bool              SetParams(const string symbol,
                               const uint fast_period,
                               const uint slow_period,
                               const uint signal_period,
                               const ENUM_APPLIED_PRICE price,
                               const uint shift,
                               )
     {
      m_params.symbol=symbol;
      m_params.fast_period=fmax(1,fast_period);
      m_params.slow_period=fmax(1,slow_period);
      m_params.fast_period=fmax(1,signal_period);
      m_params.price=price;
      m_params.shift=shift;

#ifdef __MQL5__
      for(int i=0;i<TFS;i++)
        {
         m_params.handles[i]=iOsMA(m_params.symbol,
                                   tf[i],
                                   m_params.fast_period,
                                   m_params.slow_period,
                                   m_params.signal_period,
                                   m_params.price
                                   );
         if(m_params.handles[i]==INVALID_HANDLE)
            return(false);
        }
#endif
      return(true);
     }

  /**
   * Checks whether signal is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
   bool              Signal(const ENUM_TRADE_DIRECTION _cmd,const ENUM_TIMEFRAMES _tf=PERIOD_CURRENT,const int _open_method=OPEN_METHOD_1,const int open_level=0)
     {
      int index=TimeframeToIndex(_tf);
      Update(_tf);

      double level=open_level*_Point;
      //---
      int result[OPEN_METHODS];
      ArrayInitialize(result,-1);

      for(int i=0; i<OPEN_METHODS; i++)
        {
         //---
         if(_cmd==TRADE_BUY)
           {
            if((_open_method&OPEN_METHOD_1)==OPEN_METHOD_1)
               result[i]=m_val[index][4]<0.0 &&
                         m_val[index][3]<0.0 &&
                         m_val[index][2]<0.0 &&
                         m_val[index][1]<0.0 &&
                         m_val[index][0]<0.0 &&
                         m_val[index][4]>=m_val[index][3] &&
                         m_val[index][3]>=m_val[index][2] &&
                         m_val[index][2]<=m_val[index][1] &&
                         m_val[index][1]<=m_val[index][0];
            //---
            if((_open_method&OPEN_METHOD_2)==OPEN_METHOD_2)
               result[i]=m_val[index][2]<=m_val[index][1] &&
                         m_val[index][1]<=m_val[index][0];
            //---
            if((_open_method&OPEN_METHOD_3)==OPEN_METHOD_3) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_4)==OPEN_METHOD_4) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_5)==OPEN_METHOD_5) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_6)==OPEN_METHOD_6) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_7)==OPEN_METHOD_7) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_8)==OPEN_METHOD_8) result[i]=false;
           }

         //---
         if(_cmd==TRADE_SELL)
           {
            if((_open_method&OPEN_METHOD_1)==OPEN_METHOD_1)
               result[i]=m_val[index][4]>0.0 &&
                         m_val[index][3]>0.0 &&
                         m_val[index][2]>0.0 &&
                         m_val[index][1]>0.0 &&
                         m_val[index][0]>0.0 &&
                         m_val[index][4]<=m_val[index][3] &&
                         m_val[index][3]<=m_val[index][2] &&
                         m_val[index][2]>=m_val[index][1] &&
                         m_val[index][1]>=m_val[index][0];
            //---
            if((_open_method&OPEN_METHOD_2)==OPEN_METHOD_2)
               result[i]=m_val[index][2]>=m_val[index][1] &&
                         m_val[index][1]>=m_val[index][0];
            //---
            if((_open_method&OPEN_METHOD_3)==OPEN_METHOD_3) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_4)==OPEN_METHOD_4) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_5)==OPEN_METHOD_5) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_6)==OPEN_METHOD_6) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_7)==OPEN_METHOD_7) result[i]=false;
            //---
            if((_open_method&OPEN_METHOD_8)==OPEN_METHOD_8) result[i]=false;
           }
        }

      bool res_value=false;
      for(int i=0; i<OPEN_METHODS; i++)
        {
         //--- true
         if(result[i]==1)
            res_value=true;

         //--- false
         if(result[i]==0)
           {
            res_value=false;
            break;
           }
        }
      //--- done
      return(res_value);
     }
  };
//+------------------------------------------------------------------+
