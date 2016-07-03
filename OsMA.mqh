//+------------------------------------------------------------------+
//|                                                         OsMA.mqh |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

#property strict
//---
#define OSMA_VALUES  5
//---
#define CUR          0
#define PREV         1
#define FAR          2
//---
#define OPEN_METHODS    8
//---
#define OPEN_METHOD_1   1
#define OPEN_METHOD_2   2
#define OPEN_METHOD_3   4
#define OPEN_METHOD_4   8
#define OPEN_METHOD_5   16
#define OPEN_METHOD_6   32
#define OPEN_METHOD_7   64
#define OPEN_METHOD_8   128
//+------------------------------------------------------------------+
//|   TMovingAverage                                                 |
//+------------------------------------------------------------------+
struct TMacdParams
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
class CMacdTrade : public CBasicTrade
  {
private:
   TMacdParams       m_params;
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
   //+------------------------------------------------------------------+
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
