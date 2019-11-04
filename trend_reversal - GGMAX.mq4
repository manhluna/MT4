//+---------------------------------------------------------------------+ 
//| Code: Trend Slope Trading Direction                                 |
//| This code is originally developed by Wizard Serg as an indicator    |
//| the moving direction of the FX pairs in 2006 in Forex Magazine 104  |
//| The code has been modified for other application and not applicable |
//| for any commercialize purposes. This code is modified by DH for     |
//| mid term trading.                                                   |
//+---------------------------------------------------------------------+

#property indicator_chart_window 
#property indicator_buffers 2 
#property indicator_color1 DarkGreen 
#property indicator_color2 Red

//---- input parameters 
extern int       period=20; 
extern int       method=2;                         // MODE_SMA 
extern int       price=0;                          // PRICE_CLOSE 

//---- buffers 
double Uptrend[];
double Dntrend[];
double ExtMapBuffer[]; 
double alertTag;

//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int init() 
{ 
    IndicatorBuffers(3);  
    SetIndexBuffer(0, Uptrend); 
    //ArraySetAsSeries(Uptrend, true); 
    SetIndexBuffer(1, Dntrend); 
    //ArraySetAsSeries(Dntrend, true); 
    SetIndexBuffer(2, ExtMapBuffer); 
    ArraySetAsSeries(ExtMapBuffer, true);     
    SetIndexStyle(0,DRAW_ARROW,STYLE_DOT,1,DarkGreen);
    SetIndexStyle(1,DRAW_ARROW,STYLE_DOT,1,Red);   
    IndicatorShortName("Signal Line("+period+")"); 
    return(0); 
} 

//+------------------------------------------------------------------+ 
//| Custor indicator deinitialization function                       | 
//+------------------------------------------------------------------+ 
int deinit() 
{ 
    // ???? ????? ?????? ?????? 
    return(0); 
} 

//+------------------------------------------------------------------+ 
//| Using Weight Moving Average                                      | 
//+------------------------------------------------------------------+ 
double WMA(int x, int p) 
{ 
    return(iMA(NULL, 0, p, 0, method, price, x));    
} 

//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int start() 
{ 
  int counted_bars = IndicatorCounted();    
  if(counted_bars < 0) 
  return(-1); 
                  
  int x = 0; 
  int p = MathSqrt(period);              
  int e = Bars - counted_bars + period + 1; 
    
  double vect[], trend[]; 
    
  if(e > Bars) e = Bars;    

  ArrayResize(vect, e); 
  ArraySetAsSeries(vect, true);
  ArrayResize(trend, e); 
  ArraySetAsSeries(trend, true); 
    
  for(x = 0; x < e; x++) 
  { 
    vect[x] = 2*WMA(x, period/2) - WMA(x, period);
  } 

  for(x = 0; x < e-period; x++)     
    ExtMapBuffer[x] = iMAOnArray(vect, 0, p, 0, method, x);        
    
  for(x = e-period; x >= 0; x--)
  {     
    trend[x] = trend[x+1];
    if (ExtMapBuffer[x]> ExtMapBuffer[x+1]) trend[x] =1;
    if (ExtMapBuffer[x]< ExtMapBuffer[x+1]) trend[x] =-1;    

    if (trend[x]>0)
      {
        Uptrend[x] = ExtMapBuffer[x]; 
        if (trend[x+1]<0) Uptrend[x+1]=ExtMapBuffer[x+1];
        if (alertTag!=Time[0])
          {
            PlaySound("alert.wav"); //sell wav
            Alert(Symbol(),"  M",Period()," - trend:  DN!   DN!");
          }    
        alertTag = Time[0];
        Dntrend[x] = EMPTY_VALUE;
      }
      
    else              
    if (trend[x]<0)
      { 
        Dntrend[x] = ExtMapBuffer[x]; 
        if (trend[x+1]>0) Dntrend[x+1]=ExtMapBuffer[x+1];
        if ( alertTag!=Time[0])
          {
            PlaySound("alert.wav"); //buy wav
            Alert(Symbol(),"  M",Period()," - trend:  UP!   UP!");
          }
        alertTag = Time[0];
        Uptrend[x] = EMPTY_VALUE;
      }              
  }    
  return(0); 
} 
//End Program 