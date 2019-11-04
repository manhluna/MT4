//+------------------------------------------------------------------+
//|                                        TriangularMA centered.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_chart_window
#property indicator_buffers    3
#property indicator_color1     White
#property indicator_color2     C'110,0,220'
#property indicator_color3     C'0,120,0'
#property indicator_style1     STYLE_DASH
#property indicator_style2     STYLE_DOT
#property indicator_style3     STYLE_DOT
#property indicator_width1     1
#property indicator_width2     1
#property indicator_width3     1


//
//
//
//
//

extern string TimeFrame          = "current time frame";
extern int    HalfLength         = 26;
extern int    Price              = PRICE_MEDIAN;
extern int    Shiftt             = 0;

extern double AtrLength          = 100;
extern double T3Hot              = 1.0;
extern bool   T3Original         = false;
extern double upperAtrMultiplier = 1.618;
extern double lowerAtrMultiplier = 1.618;

extern bool   alertsOn           = false;
extern bool   alertsOnCurrent    = false;
extern bool   alertsOnHighLow    = true;
extern bool   alertsMessage      = true;
extern bool   alertsSound        = false;
extern bool   alertsEmail        = false;

//
//
//
//
//

double buffer1[];
double buffer2[];
double buffer3[];
double atr[];
double temp[];
double trend[];

string indicatorFileName;
bool   calculateTMA;
bool   returnBars;
int    timeFrame;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

int init()
{
   HalfLength=MathMax(HalfLength,1);
         IndicatorBuffers(6);
         SetIndexBuffer(0,buffer1); SetIndexDrawBegin(0,HalfLength);
         SetIndexBuffer(1,buffer2); SetIndexDrawBegin(1,HalfLength);
         SetIndexBuffer(2,buffer3); SetIndexDrawBegin(2,HalfLength);
         SetIndexBuffer(3,atr);
         SetIndexBuffer(4,temp);
         SetIndexBuffer(5,trend);
         
         SetIndexShift(0,Shiftt);
         SetIndexShift(1,Shiftt);
         SetIndexShift(2,Shiftt);
         SetIndexShift(3,Shiftt);
         SetIndexShift(4,Shiftt);
         SetIndexShift(5,Shiftt);
         
         //
         //
         //
         //
         //
   
         indicatorFileName = WindowExpertName();
         returnBars        = TimeFrame=="returnBars";   if (returnBars)   return(0);
         calculateTMA      = TimeFrame=="calculateTMA"; if (calculateTMA) return(0);
         timeFrame         = stringToTimeFrame(TimeFrame);
      
    IndicatorShortName(timeFrameToString(timeFrame)+"   TriangularMa centered bands");
   return(0);
}

int deinit() { return(0); }

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
   int counted_bars=IndicatorCounted();
   int i,j,k,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
           limit=MathMin(Bars-1,MathMax(Bars-counted_bars,HalfLength));
           if (returnBars)  { buffer1[0] = limit+1; return(0); }
           
   //
   //
   //
   //
   //
           
   if (calculateTMA || timeFrame==Period())
   {
     for (i=limit; i>=0; i--) temp[i] = MathMax(High[i],Close[i+1]) - MathMin(Low[i],Close[i+1]);
     for (i=limit; i>=0; i--)
     {
        double sum  = (HalfLength+1)*iMA(NULL,0,1,0,MODE_SMA,Price,i);
        double sumw = (HalfLength+1);
        for(j=1, k=HalfLength; j<=HalfLength; j++, k--)
        {
         sum  += k*iMA(NULL,0,1,0,MODE_SMA,Price,i+j);
         sumw += k;

         if (j<=i)
         {
            sum  += k*iMA(NULL,0,1,0,MODE_SMA,Price,i-j);
            sumw += k;
         }
      }

      //
      //
      //
      //
      //
              atr[i] = iT3(temp[i],AtrLength,T3Hot,T3Original,i);
      double uprange = atr[i] * upperAtrMultiplier;
      double dnrange = atr[i] * lowerAtrMultiplier;
         buffer1[i]  = sum/sumw;
         buffer2[i]  = buffer1[i] + uprange;
         buffer3[i]  = buffer1[i] - dnrange;
           trend[i]  = 0;                     
           if (alertsOnHighLow)       
           {
              if (High[i] > buffer1[i]) trend[i] = -1;
              if (Low[i]  < buffer2[i]) trend[i] =  1;
           }
           else
           {
              if (Close[i] > buffer1[i]) trend[i] = -1;
              if (Close[i] < buffer2[i]) trend[i] =  1;
           }
      }
      if (!calculateTMA) manageAlerts();
   return(0);
   }
   
   //
   //
   //
   //
   //
      
   limit = MathMax(limit,MathMin(Bars-1,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
   for (i=limit; i>=0; i--)
   {
      int y = iBarShift(NULL,timeFrame,Time[i]);
         buffer1[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",HalfLength,Price,AtrLength,T3Hot,T3Original,upperAtrMultiplier,lowerAtrMultiplier,0,y);
         buffer2[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",HalfLength,Price,AtrLength,T3Hot,T3Original,upperAtrMultiplier,lowerAtrMultiplier,1,y);
         buffer3[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",HalfLength,Price,AtrLength,T3Hot,T3Original,upperAtrMultiplier,lowerAtrMultiplier,2,y);
         trend[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateTma",HalfLength,Price,AtrLength,T3Hot,T3Original,upperAtrMultiplier,lowerAtrMultiplier,5,y);
         
    }

   //
   //
   //
   //
   //
      
   manageAlerts();
return(0);
}

//+------------------------------------------------------------------
//|
//+------------------------------------------------------------------
//
//
//
//
//

double workT3[][6];
double workT3Coeffs[][6];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3
#define _c4     4
#define _alpha  5

//
//
//
//
//

double iT3(double price, double period, double hot, bool original, int i, int forInstance=0)
{
   if (ArrayRange(workT3,0) !=Bars)                  ArrayResize(workT3,Bars);
   if (ArrayRange(workT3Coeffs,0) < (forInstance+1)) ArrayResize(workT3Coeffs,forInstance+1);

   if (workT3Coeffs[forInstance][_period] != period)
   {
     workT3Coeffs[forInstance][_period] = period;
        double a = hot;
            workT3Coeffs[forInstance][_c1] = -a*a*a;
            workT3Coeffs[forInstance][_c2] = 3*a*a+3*a*a*a;
            workT3Coeffs[forInstance][_c3] = -6*a*a-3*a-3*a*a*a;
            workT3Coeffs[forInstance][_c4] = 1+3*a+a*a*a+3*a*a;
            if (original)
                 workT3Coeffs[forInstance][_alpha] = 2.0/(1.0 + period);
            else workT3Coeffs[forInstance][_alpha] = 2.0/(2.0 + (period-1.0)/2.0);
   }
   
   //
   //
   //
   //
   //
   
   int buffer = forInstance*6;
   int r = Bars-i-1;
   if (r == 0)
      {
         workT3[r][0+buffer] = price;
         workT3[r][1+buffer] = price;
         workT3[r][2+buffer] = price;
         workT3[r][3+buffer] = price;
         workT3[r][4+buffer] = price;
         workT3[r][5+buffer] = price;
      }
   else
      {
         workT3[r][0+buffer] = workT3[r-1][0+buffer]+workT3Coeffs[forInstance][_alpha]*(price              -workT3[r-1][0+buffer]);
         workT3[r][1+buffer] = workT3[r-1][1+buffer]+workT3Coeffs[forInstance][_alpha]*(workT3[r][0+buffer]-workT3[r-1][1+buffer]);
         workT3[r][2+buffer] = workT3[r-1][2+buffer]+workT3Coeffs[forInstance][_alpha]*(workT3[r][1+buffer]-workT3[r-1][2+buffer]);
         workT3[r][3+buffer] = workT3[r-1][3+buffer]+workT3Coeffs[forInstance][_alpha]*(workT3[r][2+buffer]-workT3[r-1][3+buffer]);
         workT3[r][4+buffer] = workT3[r-1][4+buffer]+workT3Coeffs[forInstance][_alpha]*(workT3[r][3+buffer]-workT3[r-1][4+buffer]);
         workT3[r][5+buffer] = workT3[r-1][5+buffer]+workT3Coeffs[forInstance][_alpha]*(workT3[r][4+buffer]-workT3[r-1][5+buffer]);
      }

   //
   //
   //
   //
   //
   
   return(workT3Coeffs[forInstance][_c1]*workT3[r][5+buffer] + 
          workT3Coeffs[forInstance][_c2]*workT3[r][4+buffer] + 
          workT3Coeffs[forInstance][_c3]*workT3[r][3+buffer] + 
          workT3Coeffs[forInstance][_c4]*workT3[r][2+buffer]);
}

//
//
//
//
//

void manageAlerts()
{
   if (alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] == 1) doAlert(whichBar,"lower");
         if (trend[whichBar] ==-1) doAlert(whichBar,"upper");
      }         
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," "+timeFrameToString(timeFrame)+" Tma bands price penetrated ",doWhat," band");
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol(),"Tma bands "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = StringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int ch = StringGetChar(s, length);
         if((ch > 96 && ch < 123) || (ch > 223 && ch < 256))
                     s = StringSetChar(s, length, ch - 32);
         else if(ch > -33 && ch < 0)
                     s = StringSetChar(s, length, ch + 224);
   }
   return(s);
}   

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//


