//+------------------------------------------------------------------+
//|                                     Fractals - adjustable period |
//+------------------------------------------------------------------+
#property link      "www.forex-tsd.com"
#property copyright "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1  DeepSkyBlue
#property indicator_color2  PaleVioletRed
#property indicator_width1  2
#property indicator_width2  2

//
//
//
//
//

extern int    FractalPeriod          = 25;
extern double UpperArrowDisplacement = 0.2;
extern double LowerArrowDisplacement = 0.2;
extern color  UpperCompletedColor    = DeepSkyBlue;
extern color  UpperUnCompletedColor  = Aqua;
extern color  LowerCompletedColor    = PaleVioletRed;
extern color  LowerUnCompletedColor  = HotPink;
extern int    CompletedWidth         = 2;
extern int    UnCompletedWidth       = 1;
extern string UniqueID               = "FractalTrendLines1";

double UpperBuffer[];
double LowerBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   if (MathMod(FractalPeriod,2)==0)
         FractalPeriod = FractalPeriod+1;
   SetIndexBuffer(0,UpperBuffer); SetIndexStyle(0,DRAW_ARROW); SetIndexArrow(0,159);
   SetIndexBuffer(1,LowerBuffer); SetIndexStyle(1,DRAW_ARROW); SetIndexArrow(1,159);
}
int deinit()
{
   ObjectDelete(UniqueID+"up1");
   ObjectDelete(UniqueID+"up2");
   ObjectDelete(UniqueID+"dn1");
   ObjectDelete(UniqueID+"dn2");
   return(0); 
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int start()
{
   int half = FractalPeriod/2;
   int i,limit,counted_bars=IndicatorCounted();

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(MathMax(Bars-counted_bars,FractalPeriod),Bars-1);

   //
   //
   //
   //
   //

   for(i=limit; i>=0; i--)
   {
         bool   found     = true;
         double compareTo = High[i];
         for (int k=1;k<=half;k++)
            {
               if ((i+k)<Bars && High[i+k]> compareTo) { found=false; break; }
               if ((i-k)>=0   && High[i-k]>=compareTo) { found=false; break; }
            }
         if (found) 
               UpperBuffer[i]=High[i]+iATR(NULL,0,20,i)*UpperArrowDisplacement;
         else  UpperBuffer[i]=EMPTY_VALUE;

      //
      //
      //
      //
      //
      
         found     = true;
         compareTo = Low[i];
         for (k=1;k<=half;k++)
            {
               if ((i+k)<Bars && Low[i+k]< compareTo) { found=false; break; }
               if ((i-k)>=0   && Low[i-k]<=compareTo) { found=false; break; }
            }
         if (found)
              LowerBuffer[i]=Low[i]-iATR(NULL,0,20,i)*LowerArrowDisplacement;
         else LowerBuffer[i]=EMPTY_VALUE;
   }
 
 
   //
   //
   //
   //
   //

      int lastUp[3];
      int lastDn[3];
         int dnInd = -1;
         int upInd = -1;
         for (i=0; i<Bars; i++)
         {
            if (upInd<2 && UpperBuffer[i] != EMPTY_VALUE) { upInd++; lastUp[upInd] = i; }
            if (dnInd<2 && LowerBuffer[i] != EMPTY_VALUE) { dnInd++; lastDn[dnInd] = i; }
               if (upInd==2 && dnInd==2) break;
         }
         createLine("up1",High[lastUp[1]],Time[lastUp[1]],High[lastUp[0]],Time[lastUp[0]],UpperUnCompletedColor,UnCompletedWidth);
         createLine("up2",High[lastUp[2]],Time[lastUp[2]],High[lastUp[1]],Time[lastUp[1]],UpperCompletedColor,CompletedWidth);
         createLine("dn1",Low[lastDn[1]] ,Time[lastDn[1]],Low[lastDn[0]] ,Time[lastDn[0]],LowerUnCompletedColor,UnCompletedWidth);
         createLine("dn2",Low[lastDn[2]] ,Time[lastDn[2]],Low[lastDn[1]] ,Time[lastDn[1]],LowerCompletedColor,CompletedWidth);
   return(0);
}

//
//
//
//
//

void createLine(string add, double price1, datetime time1, double price2, datetime time2, color theColor, int width)
{
   string name = UniqueID+add;
      ObjectDelete(name);
      ObjectCreate(name,OBJ_TREND,0,time1,price1,time2,price2);
         ObjectSet(name,OBJPROP_COLOR,theColor);
         ObjectSet(name,OBJPROP_WIDTH,width);
}