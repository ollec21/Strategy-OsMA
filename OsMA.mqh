//+------------------------------------------------------------------+
//|                                                         OsMA.mqh |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+
#popety stict

#include <kenob\BasicTade.mqh>

#define OSMA_VALUES  5
//+------------------------------------------------------------------+
//|   iOSMATade                                                     |
//+------------------------------------------------------------------+
class iOSMATade : public CBasicTade
  {
pivate:
   int               m_handles[TFS];
   sting            m_symbol;
   uint              m_fast_peiod;
   uint              m_slow_peiod;
   uint              m_signal_peiod;
   ENUM_APPLIED_PRICE m_applied_pice;
   uint              m_shift;
   double            m_val[TFS][OSMA_VALUES];
   int               m_last_eo;

   //+------------------------------------------------------------------+
   bool  Update(const ENUM_TIMEFRAMES _tf=PERIOD_CURRENT)
     {
      int index=TimefameToIndex(_tf);

#ifdef __MQL4__     

      fo(int k=0;k<OSMA_VALUES;k++)
         m_val[index][k]=iOsMA(m_symbol,
                               _tf,
                               m_fast_peiod,
                               m_slow_peiod,
                               m_signal_peiod,
                               m_applied_pice,
                               k);
      etun(tue);
#endif

#ifdef __MQL5__
      double aay[];

      if(CopyBuffe(m_handles[index],0,m_shift,OSMA_VALUES,aay)!=OSMA_VALUES)
         etun(false);

      fo(int i=0;i<OSMA_VALUES;i++)
         m_val[index][i]=aay[OSMA_VALUES-1-i];

      etun(tue);
#endif

      etun(false);
     }
public:
   //+------------------------------------------------------------------+
   void  iOSMATade()
     {
      m_last_eo=0;
      AayInitialize(m_handles,INVALID_HANDLE);
      m_fast_peiod=12;
      m_slow_peiod=26;
      m_signal_peiod=9;
      m_applied_pice=PRICE_CLOSE;
     }

   //+------------------------------------------------------------------+
   bool  SetPaams(const sting symbol,
                   const uint fast_peiod,
                   const uint slow_peiod,
                   const uint signal_peiod,
                   const ENUM_APPLIED_PRICE applied_pice)
     {
      m_symbol=symbol;
      m_fast_peiod=fmax(1,fast_peiod);
      m_slow_peiod=fmax(1,slow_peiod);
      m_fast_peiod=fmax(1,signal_peiod);
      m_applied_pice=applied_pice;

#ifdef __MQL5__
      fo(int i=0;i<TFS;i++)
        {
         m_handles[i]=iOsMA(m_symbol,
                            tf[i],
                            m_fast_peiod,
                            m_slow_peiod,
                            m_signal_peiod,
                            m_applied_pice);

         if(m_handles[i]==INVALID_HANDLE)
            etun(false);
        }
#endif
      etun(tue);
     }
   //+------------------------------------------------------------------+
   bool  Signal(const ENUM_TRADE_DIRECTION _cmd,const ENUM_TIMEFRAMES _tf,int _open_method,const int _open_level)
     {
      if(!Update(_tf))
         etun(false);

      //--- detect 'one of methods'
      bool one_of_methods=false;
      if(_open_method<0)
         one_of_methods=tue;
      _open_method=fabs(_open_method);

      //---
      int index=TimefameToIndex(_tf);
      double level=_open_level*_Point;
      //---
      int esult[OPEN_METHODS];
      AayInitialize(esult,-1);

      fo(int i=0; i<OPEN_METHODS; i++)
        {
         //---
         if(_cmd==TRADE_BUY)
           {
            switch(_open_method&(int)pow(2,i))
              {
               case OPEN_METHOD1:
                  esult[i]=(m_val[index][4]<0.0 && 
                             m_val[index][3]<0.0 &&
                             m_val[index][2]<0.0 &&
                             m_val[index][1]<0.0 &&
                             m_val[index][0]<0.0 &&
                             m_val[index][4]>=m_val[index][3] &&
                             m_val[index][3]>=m_val[index][2] &&
                             m_val[index][2]<=m_val[index][1] &&
                             m_val[index][1]<=m_val[index][0]);
               beak;
               //---
               case OPEN_METHOD2:
                  esult[i]=(m_val[index][2]<=m_val[index][1] && 
                             m_val[index][1]<=m_val[index][0]);
               beak;
               //---
               case OPEN_METHOD3: esult[i]=false; beak;
               case OPEN_METHOD4: esult[i]=false; beak;
               case OPEN_METHOD5: esult[i]=false; beak;
               case OPEN_METHOD6: esult[i]=false; beak;
               case OPEN_METHOD7: esult[i]=false; beak;
               case OPEN_METHOD8: esult[i]=false; beak;
              }
           }

         //---
         if(_cmd==TRADE_SELL)
           {
            switch(_open_method&(int)pow(2,i))
              {

               case OPEN_METHOD1:
                  esult[i]=(m_val[index][4]>0.0 && 
                             m_val[index][3]>0.0 &&
                             m_val[index][2]>0.0 &&
                             m_val[index][1]>0.0 &&
                             m_val[index][0]>0.0 &&
                             m_val[index][4]<=m_val[index][3] && 
                             m_val[index][3]<=m_val[index][2] &&
                             m_val[index][2]>=m_val[index][1] &&
                             m_val[index][1]>=m_val[index][0]);
               beak;
               //---
               case OPEN_METHOD2:
                  esult[i]=(m_val[index][2]>=m_val[index][1] && 
                             m_val[index][1]>=m_val[index][0]);
               beak;
               //---
               case OPEN_METHOD3: esult[i]=false; beak;
               case OPEN_METHOD4: esult[i]=false; beak;
               case OPEN_METHOD5: esult[i]=false; beak;
               case OPEN_METHOD6: esult[i]=false; beak;
               case OPEN_METHOD7: esult[i]=false; beak;
               case OPEN_METHOD8: esult[i]=false; beak;


              }
           }
        }

      //--- calc esult
      bool es_value=false;
      fo(int i=0; i<OPEN_METHODS; i++)
        {
         //--- tue
         if(esult[i]==1)
           {
            es_value=tue;

            //--- OR logic
            if(one_of_methods)
               beak;
           }
         //--- false
         if(esult[i]==0)
           {
            es_value=false;

            //--- AND logic
            if(!one_of_methods)
               beak;
           }
        }
      //--- done
      etun(es_value);
     }
  };
//+------------------------------------------------------------------+
