//+------------------------------------------------------------------+
//|                                                    StopEater.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <fxlabsnet.mqh>

#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define OANDA_REQUEST_DURATION (2)
#define OANDA_REFLESH_SPAN (20)

bool fatal_error = false;
string symbol;

int pp_sz;
double pricepoints[];
double pendingOrders[];
double positionPressure = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  init_fxlabs(); 
  fatal_error = false;
  symbol = Symbol();
  int pos = StringLen(symbol) - 3;
  symbol = StringConcatenate(StringSubstr(symbol, 0, pos), "_", StringSubstr(symbol, pos));

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
  
bool checkArrayResize(int newsz, int sz)
{
   if (newsz != sz) 
   {
      Alert("ArrayResize failed"); 
      return(false); 
   }
   return(true); 
}

bool triggerOandaUpdate() {

   int m = Minute();
   int s = Seconds();

   if((0 <= m && m < OANDA_REQUEST_DURATION) || (20 <= m && m < 20 + OANDA_REQUEST_DURATION) || (40 <= m && m < 4 + OANDA_REQUEST_DURATION)) {
      if(!(m % OANDA_REFLESH_SPAN)) {
         return true;
      }
   }
   
   return false;
}

void askOandaUpdate() {
   if(fatal_error) {
      Print("fatal error");
      return; 
   }
   if(!triggerOandaUpdate()) {
      return;
   }

   int sz = 0;
   int ref = -1; 

// ref = orderbook(symbol, Time[1] - TimeCurrent());
   ref = orderbook(symbol, 0);
   if(ref >= 0) {
      sz = orderbook_sz(ref);
      if(sz < 0) {
         fatal_error = true; 
         Print("Error retrieving size of Orderbook data, sz = ", sz); 
         return; 
      }
   }
     
   if (sz == 0) {
      Print("size = 0, returning.");
      return;
   }
   
   int idx = 0;
   int ts = orderbook_timestamp(ref, idx);
   if (ts == -1) {
      Print("orderbook_timestamps error");
      return;   
   }

   pp_sz = orderbook_price_points_sz(ref, ts);
   double ps[]; 
   double pl[]; 
   double os[]; 
   double ol[];

   double pressure = 0;

   // we should verify ArrayResize worked, but for sake
   // of brevity we omit this from the sample code
   ArrayResize(pricepoints, pp_sz);
   ArrayResize(ps, pp_sz); 
   ArrayResize(pl, pp_sz); 
   ArrayResize(os, pp_sz); 
   ArrayResize(ol, pp_sz); 

   ArrayResize(pendingOrders, pp_sz); 

   if(!orderbook_price_points(ref, ts, pricepoints, ps, pl, os, ol)) {
      return; 
   }  
                  
   for(int i = 0; i < pp_sz; i++) {
      pendingOrders[i] = ol[i] - os[i];
      pressure -= pl[i] - ps[i];
//      if(MathAbs(pricepoints[i] - Bid) < 1.0) {
//         Print(pricepoints[i], ", ", ps[i], ", ", pl[i], ", ", os[i], ", ", ol[i]);
//      }
   }

   return pressure;
}

void writeOrderBookInfo() {
 
   if(FileIsExist(symbol + ".csv")) {
      FileDelete(symbol + ".csv");
   }

   int fh = FileOpen(symbol + ".csv", FILE_CSV | FILE_WRITE);
   if(filehandle!=INVALID_HANDLE) {
      FileWrite(fh, positionPressure);

      for(int i = 0; i < pp_sz; i++) {
        FileWrite(fh, pricepoints[i], pendingOrders[i]);
      }
   }

   FileClose(fh);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

   double pressure = askOandaUpdate();
   if(positionPressure == pressure) {
      return;
   }
   else {
      positionPressure = pressure;
      writeOrderBookInfo();
   }   
}
//+------------------------------------------------------------------+
