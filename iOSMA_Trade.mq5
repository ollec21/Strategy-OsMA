//+------------------------------------------------------------------+
//|                                                  iOSMA_Trade.mq4 |
//|                            Copyright 2016, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict
//---
#define EXPERT_NAME     "iOSMA_Trade"
#define EXPERT_VERSION  "1.00"
#property version       EXPERT_VERSION
//---
#include <kenorb\OSMA.mqh>
//+------------------------------------------------------------------+
//|   Input parameters                                               |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES InpTimeframe=PERIOD_H1;// Timeframe
input uint  InpFastPeriod=12;                // Fast Period
input uint  InpSlowPeriod=26;                // Slow Period
input uint  InpSignalPeriod=9;               // Signal Period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE;// Applied Price
input ENUM_OPEN_METHOD  InpOpenMethod=OPEN_METHOD1;// Open Method
input uint  InpOneOfMethods=3;               // One Of Methods, ex: 7 (1 or 2 or 4)
input uint  InpSumOfMethods=3;               // Sum Of Methods, ex: 7 (1 and 2 and 4)
input uint  InpOpenLevel=0;                  // Open Level, pips
sinput double InpVolume=0.01;                // Volume
input uint  InpTakeProfit=0;                 // Take Profit, pips
input uint  InpStopLoss=0;                   // Stop Loss, pips
input bool  InpCloseOpposite=true;           // Close Opposite Positions
sinput uint InpMagicNumber=12345;            // Magic Number

//--- global vars
iOSMATrade osma;
const ENUM_RUN_MODE run_mode=GetRunMode();
bool init_error;
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---    
   if(!osma.SetParams(_Symbol,InpFastPeriod,InpSlowPeriod,InpSignalPeriod,InpAppliedPrice))
      return(INIT_FAILED);
//---
   init_error=false;
   if(run_mode==RUN_LIVE)
     {
      EventSetTimer(1);
      OnTimer();
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|   OnDeinit                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
//+------------------------------------------------------------------+
//|   OnTimer                                                        |
//+------------------------------------------------------------------+
void OnTimer()
  {

//--- checking settings
   if(run_mode==RUN_LIVE)
     {
      bool check[4];
      string msg[4];

      //---
      check[0]=TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
      msg[0]="\n\nAuto trading in the terminal is allowed:  "+BoolToString(check[0]);
      //---
      check[1]=AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
      msg[1]="\n\nTrade for this account is enabled:  "+BoolToString(check[1]);
      //---
      check[2]=AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
      msg[2]="\n\nTrade experts for this account is enabled:  "+BoolToString(check[2]);
      //---
      check[3]=MQLInfoInteger(MQL_TRADE_ALLOWED);
      msg[3]="\n\nThe expert is allowed to trade:  "+BoolToString(check[3]);
      //---
      init_error=false;
      int total=ArraySize(check);
      for(int i=0; i<total; i++)
        {
         if(!check[i])
           {
            init_error=true;
            string comment=StringFormat("\nExpert: %s v.%s",EXPERT_NAME,EXPERT_VERSION);
            for(int k=0; k<total; k++)
               comment+=msg[k];
            Comment(comment);
            return;
           }
        }
     }
//---
   string comment=StringFormat("\nExpert: %s v.%s",EXPERT_NAME,EXPERT_VERSION);
   comment+="\n\nIndicator: "      + StringFormat("OSMA (%d, %d, %d, %s)",InpFastPeriod,InpSlowPeriod,InpSignalPeriod,StringSubstr(EnumToString(InpAppliedPrice),6));
   comment+="\n\nTimeframe: "      + TimeframeToString(InpTimeframe);
   comment+="\n\nOpen Method: "    + OpenMethodToString(InpOpenMethod,InpOneOfMethods,InpSumOfMethods);
   comment+="\n\nOpen Level: "     + IntegerToString(InpOpenLevel);
   comment+="\n\nVolume: "         + DoubleToString(InpVolume,2);
   comment+="\n\nTake Profit: "    + IntegerToString(InpTakeProfit)+" pips";
   comment+="\n\nStop Loss: "      + IntegerToString(InpStopLoss)+" pips";
   comment+="\n\nClose Opposite: " + (InpCloseOpposite?"yes":"no");
   comment+="\n\nMagic Number: "   + IntegerToString(InpMagicNumber);
   Comment(comment);
  }
//+------------------------------------------------------------------+
//|   OnTick                                                         |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- checking init errors
   if(init_error)
      return;

//--- BUY
   bool signal_buy=osma.Signal(TRADE_BUY,(ENUM_TIMEFRAMES)InpTimeframe,GetOpenMethod(InpOpenMethod,InpOneOfMethods,InpSumOfMethods),InpOpenLevel);
   if(signal_buy)
     {
      TDealTime last_time;
      if(!DealLastTime(last_time,_Symbol,InpMagicNumber))
         return;
      //---
      TPositionCount pos_count;
      if(!PositonTotal(pos_count,_Symbol,InpMagicNumber))
         return;
      //---
      if(last_time.buy_time<Time(_Symbol,InpTimeframe,0) &&
         ((!InpCloseOpposite && pos_count.sell_count+pos_count.buy_count==0) ||
         (InpCloseOpposite && pos_count.buy_count==0)))
        {
         //---
         if(InpCloseOpposite && pos_count.sell_count>0)
            if(!PositionCloseAll(_Symbol,POSITION_TYPE_SELL,InpMagicNumber))
               return;
         //---
         string order_comment=EXPERT_NAME+" v."+EXPERT_VERSION+" mn:"+IntegerToString(InpMagicNumber);
         if(!osma.Trade(_Symbol,TRADE_BUY,InpVolume,InpStopLoss,InpTakeProfit,order_comment,InpMagicNumber))
            Print("Error ",osma.GetLastError());
         return;
        }
     }

//--- SELL
   bool signal_sell=osma.Signal(TRADE_SELL,(ENUM_TIMEFRAMES)InpTimeframe,GetOpenMethod(InpOpenMethod,InpOneOfMethods,InpSumOfMethods),InpOpenLevel);
   if(signal_sell)
     {
      TDealTime last_time;
      if(!DealLastTime(last_time,_Symbol,InpMagicNumber))
         return;
      //---
      TPositionCount pos_count;
      if(!PositonTotal(pos_count,_Symbol,InpMagicNumber))
         return;
      //---
      if(last_time.sell_time<Time(_Symbol,InpTimeframe,0) &&
         ((!InpCloseOpposite && pos_count.sell_count+pos_count.buy_count==0) ||
         (InpCloseOpposite && pos_count.sell_count==0)))
        {
         //---
         if(InpCloseOpposite && pos_count.buy_count>0)
            if(!PositionCloseAll(_Symbol,POSITION_TYPE_BUY,InpMagicNumber))
               return;
         //---
         string order_comment=EXPERT_NAME+" v."+EXPERT_VERSION+" mn:"+IntegerToString(InpMagicNumber);
         if(!osma.Trade(_Symbol,TRADE_SELL,InpVolume,InpStopLoss,InpTakeProfit,order_comment,InpMagicNumber))
            Print("Error ",osma.GetLastError());
         //---
         return;
        }
     }
  }
//+------------------------------------------------------------------+
