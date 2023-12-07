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

ulong posTicket;

double RiskPercent = 1;

double buyPrice = 0;
double newTP = 0;
double newSL = 0;
bool temp = false;
int handleHA;
double take_profit = 0;
double stop_loss = 0;

int macd;

int barsTotal;

double LowestLowPrice[5] = {DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX};

void StoreLowValue(double low_value) {
   LowestLowPrice[0] = LowestLowPrice[1];
   LowestLowPrice[1] = LowestLowPrice[2];
   LowestLowPrice[2] = LowestLowPrice[3];
   LowestLowPrice[3] = LowestLowPrice[4];
   LowestLowPrice[4] = low_value;
}

double CalculateStopLoss() {
   int index = ArrayMinimum(LowestLowPrice);
   return LowestLowPrice[index];
}


bool BullPrevVal[3]= {false, false, false}; 


void UpdateLastThreeValues(bool bullish_flag) {
  // Shift the values to make space for the new value
  BullPrevVal[0] = BullPrevVal[1];
  BullPrevVal[1] = BullPrevVal[2];
   
  // Get and store the latest closing value
  BullPrevVal[2] = bullish_flag; // Assumes you want the previous candle's close

}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   barsTotal = iBars(_Symbol, PERIOD_CURRENT); 
  
   
   macd = iCustom(_Symbol, PERIOD_CURRENT,"Examples\\MACD.ex5" );
   
   handleHA = iCustom(_Symbol, PERIOD_CURRENT, "HA2.ex5");
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Get the number of bars
    int bars = iBars(_Symbol, PERIOD_CURRENT);
    
   if (posTicket > 0)
   {
       double current = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
       temp = (current-buyPrice) >= (0.75 * (take_profit - buyPrice));
       //Print(__FUNCTION__," condition %b", temp);
       if (temp)
       {
           Print(__FUNCTION__," modify position");
           newTP = take_profit + (buyPrice - stop_loss);
           newSL = stop_loss + (buyPrice - stop_loss);
           
           // Modify the stop loss and take profit
            if (PositionSelectByTicket(posTicket)) {
                // Modify the position's stop loss and take profit levels using PositionModify
                if (trade.PositionModify(posTicket, newSL, newTP)) {
                    // Modification successful
                        buyPrice = current;
                        take_profit = newTP;
                        stop_loss = newSL;
                } else {
                    // Failed to modify the position
                    // Handle the failure scenario here
                }
            } else {
                // Position with the specified ticket not found
                // Handle the case when the position is not found
            }
       }
   }

    // Check if the number of bars has changed
    if (barsTotal != bars)
    {
        barsTotal = bars;
        

        // Arrays to store Heiken Ashi values
        double haOpen[], haClose[], haLow[];
        
        double MACD[], SIGNAL[];

        // Copy Heiken Ashi values to arrays
        CopyBuffer(handleHA, 0, 1, 1, haOpen);
        CopyBuffer(handleHA, 3, 1, 1, haClose);
        CopyBuffer(handleHA, 2, 1, 1, haLow);
        
        CopyBuffer(macd, 0, 1, 1, MACD);
        CopyBuffer(macd, 1, 1, 1, SIGNAL);
        
        
        
        StoreLowValue(haLow[0]);
        
        temp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) >= (buyPrice + 0.8 * (take_profit - buyPrice)); 
        Comment("\nHA diff============ ", temp,
                    "\n current ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits),
                    "\n stop_loss ", DoubleToString(stop_loss, _Digits),
                    "\n take_profit ", DoubleToString(take_profit, _Digits),
                    "\n newSL ", DoubleToString(newSL, _Digits),
                    "\n newTP ", DoubleToString(newTP, _Digits),
                    "\n MACD ", DoubleToString(MACD[0], _Digits));

        // Check Heiken Ashi trend
        if (haOpen[0] < haClose[0])
        {
            // Bullish trend (color DodgerBlue)
            UpdateLastThreeValues(true);

            // Retrieve account balance
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            double OnePercentBalance = balance * 0.01;

            // Get current ask price
            double currentBuyPrice  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

            // Calculate stop loss and take profit
            stop_loss = CalculateStopLoss();
            take_profit = currentBuyPrice + (currentBuyPrice - stop_loss);

            // Get contract size
            double contract_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);

            // Close existing sell position
            if (posTicket > 0)
            {
            
                //double temp = currentBuyPrice - (buyPrice + 0.8 * (take_profit - buyPrice));
                //Comment("\nHA diff============ ", DoubleToString(haOpen[0], _Digits));     
                // Check if conditions are met to update the stop loss
                //temp = currentBuyPrice >= (buyPrice + 0.8 * (take_profit - buyPrice));
                ////Print(__FUNCTION__," condition %b", temp);
                //if (temp)
                //{
                //    Print(__FUNCTION__," modify position");
                //    newTP = take_profit + (buyPrice - stop_loss);
                //    newSL = stop_loss + (buyPrice - stop_loss);
                //    if (trade.PositionModify(posTicket, newSL, newTP))
                //    {
                //        buyPrice = currentBuyPrice;
                //        take_profit = newTP;
                //        stop_loss = newSL;
                //    }
                //}
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

            // Open a buy position
            if (posTicket <= 0)
            {
                double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                entry = NormalizeDouble(entry, _Digits);
                
                double lots = calclots(RiskPercent,entry-stop_loss);
                                
                  
                if (BullPrevVal[0]==true && BullPrevVal[1]==true && BullPrevVal[2]==true && MACD[0]>0.000250 && MACD[0]>SIGNAL[0])
                 {
                   if (trade.Buy(lots, _Symbol, entry, stop_loss, take_profit))
                   {
                       posTicket = trade.ResultOrder();
                       buyPrice = entry;
                       newSL = newTP = 0;
                   }
                }
            }


            // Display information
            
        }
        else if (haOpen[0] > haClose[0])
        {
            // Bearish trend (color Red)
            UpdateLastThreeValues(false);

            // Close existing buy position
            //if (posTicket > 0)
            //{
            //    if (PositionSelectByTicket(posTicket))
            //    {
            //        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            //        {
            //            if (trade.PositionClose(posTicket))
            //            {
            //                posTicket = 0;
            //            }
            //        }
            //    }else{
            //      posTicket = 0;
            //    }
            //}

            // Open a sell position
//            if (posTicket <= 0)
//            {
//                double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
//                entry = NormalizeDouble(entry, _Digits);
//
                //double lots = calclots(RiskPercent,stop_loss-entry);

//                if (trade.Sell(0.01, _Symbol, entry, sl))
//                {
//                    posTicket = trade.ResultOrder();
//                }
//            }
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



   
//      if (BullPrevVal[0]==true && BullPrevVal[1]==true && BullPrevVal[2]==true)
//      {
//      
//         // yellow color on graph
//         
//         double balance=AccountInfoDouble(ACCOUNT_BALANCE);
//         
//         double OnePercentBalance = balance * 0.01;
//         
//         double currentBuyPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
//         
//         double stop_loss = LowestLowPrice[StopLoss()];
//         
//         double contract_size = SYMBOL_TRADE_CONTRACT_SIZE;         
//         
//         //Lots = {profit/Loss} / {(currentBuyPrice - stop_loss) x contract_size)
//                
//         double lot_size = (OnePercentBalance) / ((currentBuyPrice - stop_loss) * contract_size);
//         
//         double take_profit = currentBuyPrice + (currentBuyPrice - stop_loss);
//         
//         trade.Buy(lot_size,_Symbol,currentBuyPrice,stop_loss,take_profit);
//
//
//         
//         
////            1. find out the current account balance   
////            2. calculate 1% of total balance
////            3. get current buy price
////            4. evaluate the stop loss price
////            5. calculate lot size 
////            6. calculate diff of current and SL --  add to TP
////            
////            7. test on strategy tester
////            8. apply sell 
////            9. push on github
////           10. lot size debug 
////           11. 80 percent-- stop loss to market buy 
////           12. MACD value threshold 
////           13. posTicket code understand 
////            https://www.youtube.com/watch?v=XU3FXFg3anY
//            
//            
//                 
//      }
      
      
//      if (BullPrevVal[0]==false && BullPrevVal[1]==false && BullPrevVal[2]==false)
//      {
//      
//         // yellow color on graph
//         trade.Sell(0.01,_Symbol);
//         
//         //vol, symbol, price, sl,tp,comment
//         
//      
//      }
//      
      
      //Comment("\nHA Open ", DoubleToString(haOpen[0],_Digits),
      //        "\nHA Close ", DoubleToString(haClose[0],_Digits));   
//   }
// 
//  }
  
  
//+------------------------------------------------------------------+
