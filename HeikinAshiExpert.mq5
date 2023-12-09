//+------------------------------------------------------------------+
//|                                             HeikinAshiExpert.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade trade;

double RiskPercent = 1;
double buyPrice = 0;
double newTP = 0;
double newSL = 0;
ulong posTicket;
int macd;
int barsTotal;
int handleHA;
int rsi_handle;
bool temp = false;
bool last_trade = false; // true = bullish and false = bullish 

int RSI_period = 14;
double overbought_level = 70;
double oversold_level = 30;

double LowestLowPrice[5] = {DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX};
double HighestHighPrice[5] = {DBL_MIN, DBL_MIN, DBL_MIN, DBL_MIN, DBL_MIN};
bool BullPrevVal[3]= {false, false, false}; 



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   barsTotal = iBars(_Symbol, PERIOD_CURRENT);
   macd = iCustom(_Symbol, PERIOD_CURRENT,"Examples\\MACD.ex5" );
   handleHA = iCustom(_Symbol, PERIOD_CURRENT, "HA2.ex5");
   //rsi_handle = iCustom(_Symbol, PERIOD_CURRENT, "Examples\\RSI.ex5");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get the number of bars
    int bars = iBars(_Symbol, PERIOD_CURRENT);
    
    // Check if the number of bars has changed
    if (barsTotal != bars)
    {
        barsTotal = bars;
        
        // Arrays to store Heiken Ashi values
        double haOpen[], haClose[], haLow[], haHigh[];
        double MACD[], SIGNAL[];

        // Copy Heiken Ashi values to arrays
        CopyBuffer(handleHA, 0, 1, 1, haOpen);
        CopyBuffer(handleHA, 1, 1, 1, haHigh);
        CopyBuffer(handleHA, 2, 1, 1, haLow);
        CopyBuffer(handleHA, 3, 1, 1, haClose);
        StoreLowValue(haLow[0]);
        StoreHighValue(haHigh[0]);
        
        // Check Heiken Ashi trend
        if (haOpen[0] < haClose[0])
        {
            UpdateLastThreeValues(true);

            // Close existing sell position
            if (posTicket > 0)
            {
                maybe_close_buy_trade();
            }

            // Open a buy position
            if (posTicket <= 0)
            {
                take_buy_trade();
            }          
        }
        else if (haOpen[0] > haClose[0])
        {
            // Bearish trend (color Red)
            UpdateLastThreeValues(false);

            // Close existing buy position
            if (posTicket > 0)
            {
                maybe_close_sell_trade();
            }

            // Open a sell position
            if (posTicket <= 0)
            {
                take_sell_trade();
            }
        }
    }
}

void maybe_close_buy_trade(){
   if (PositionSelectByTicket(posTicket))
   {
     if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
     {   
         if (trade.PositionClose(posTicket))
         {
             posTicket = 0;
         }
     }
   }else{
   posTicket = 0;
   }
}

void maybe_close_sell_trade(){
   if (PositionSelectByTicket(posTicket))
   {
     if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
     {   
         if (trade.PositionClose(posTicket))
         {
             posTicket = 0;
         }
     }
   }else{
   posTicket = 0;
   }
}

void take_sell_trade(){
   double current_sell_price  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stop_loss = calculate_stoploss_for_bearish_trend();
   double take_profit = current_sell_price - (stop_loss - current_sell_price);
   double entry = NormalizeDouble(current_sell_price, _Digits);
   double lots = calclots(RiskPercent,stop_loss - entry);
   
   double MACD[], SIGNAL[];
   CopyBuffer(macd, 0, 1, 1, MACD);
   CopyBuffer(macd, 1, 1, 1, SIGNAL);
   bool condition = BullPrevVal[0]==false && BullPrevVal[1]==false && BullPrevVal[2]==false; //&& MACD[0]>0.000130 && MACD[0]>SIGNAL[0];
                 
   if (condition)
   {
    if (trade.Sell(lots, _Symbol, entry, stop_loss, take_profit))
    {
        posTicket = trade.ResultOrder();
        //buyPrice = entry;
        //newSL = newTP = 0;
    }
  }
}

void take_buy_trade(){
   double currentBuyPrice  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stopLoss = calculate_stoploss_for_bullish_trend();
   double takeProfit = currentBuyPrice + (currentBuyPrice - stopLoss);
   double entry = NormalizeDouble(currentBuyPrice, _Digits);
   double lots = calclots(RiskPercent,entry-stopLoss);
   
   double MACD[], SIGNAL[];
   CopyBuffer(macd, 0, 1, 1, MACD);
   CopyBuffer(macd, 1, 1, 1, SIGNAL);
   bool condition = BullPrevVal[0]==true && BullPrevVal[1]==true && BullPrevVal[2]==true; //&& MACD[0]>0.000130 && MACD[0]>SIGNAL[0];
                 
   if (condition)
   {
    if (trade.Buy(lots, _Symbol, entry, stopLoss, takeProfit))
    {
        posTicket = trade.ResultOrder();
        //buyPrice = entry;
        //newSL = newTP = 0;
    }
  }
}


double calclots (double risk_percent, double slDistance){
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   
   if (ticksize == 0 || tickvalue == 0 || lotstep == 0){
      Print(__FUNCTION__," > Lotsize cannot be calculated...");
      return 0;
    }
   
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE)*risk_percent /100;
   double moneyLotStep = (slDistance / ticksize) * tickvalue * lotstep;
   
   if (moneyLotStep == 0){
       Print(__FUNCTION__," > Lotsize cannot be calculated...");
       return 0;
     }
     
     double lots = MathFloor(riskMoney / moneyLotStep)*lotstep;
     return lots;  

}

void StoreLowValue(double low_value) {
   LowestLowPrice[0] = LowestLowPrice[1];
   LowestLowPrice[1] = LowestLowPrice[2];
   LowestLowPrice[2] = LowestLowPrice[3];
   LowestLowPrice[3] = LowestLowPrice[4];
   LowestLowPrice[4] = low_value;
}

void StoreHighValue(double high_value) {
   HighestHighPrice[0] = HighestHighPrice[1];
   HighestHighPrice[1] = HighestHighPrice[2];
   HighestHighPrice[2] = HighestHighPrice[3];
   HighestHighPrice[3] = HighestHighPrice[4];
   HighestHighPrice[4] = high_value;
}

double calculate_stoploss_for_bullish_trend() {
   int index = ArrayMinimum(LowestLowPrice);
   return LowestLowPrice[index];
}

double calculate_stoploss_for_bearish_trend() {
   int index = ArrayMaximum(HighestHighPrice);
   return HighestHighPrice[index];
}

void UpdateLastThreeValues(bool bullish_flag) {
  // Shift the values to make space for the new value
  BullPrevVal[0] = BullPrevVal[1];
  BullPrevVal[1] = BullPrevVal[2];
  // Get and store the latest closing value
  BullPrevVal[2] = bullish_flag; // Assumes you want the previous candle's close
}

//void ModifyStoplossTakeProfit() {
//   double current = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
//   temp = (current-buyPrice) >= (0.25 * (takeProfit - buyPrice));
//       if (temp)
//       {
//           Print(__FUNCTION__," modify position");
//           newTP = takeProfit + (buyPrice - stopLoss);
//           newSL = stopLoss + (buyPrice - stopLoss);
//           
//           // Modify the stop loss and take profit
//            if (PositionSelectByTicket(posTicket)) {
//                // Modify the position's stop loss and take profit levels using PositionModify
//                if (trade.PositionModify(posTicket, newSL, newTP)) {
//                    // Modification successful
//                        buyPrice = current;
//                        takeProfit = newTP;
//                        stopLoss = newSL;
//                } else {
//                    // Failed to modify the position
//                    // Handle the failure scenario here
//                }
//            } else {
//                // Position with the specified ticket not found
//                // Handle the case when the position is not found
//            }
//       }
//}

   
