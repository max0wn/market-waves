//+------------------------------------------------------------------+
//|                                                  MarketWaves.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1 "Price"
#property indicator_type1  DRAW_SECTION
#property indicator_color1 clrAzure
#property indicator_style1 STYLE_DASH
#property indicator_width1 1

double PriceBuffer[];

bool offline;
double slice[3];
datetime current_dt;

enum Type {
    Peak = 1,
    Bottom = 2,
};

Type type;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0, PriceBuffer, INDICATOR_DATA);
    
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);
    PlotIndexSetInteger(0, PLOT_SHIFT, 0);
    
    IndicatorSetString(INDICATOR_SHORTNAME, "Market Waves");
    IndicatorSetInteger(INDICATOR_DIGITS, Digits());
//---
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//---
    if (prev_calculated == 0) {
        offline = true;
        current_dt = 0;
        type = (Type)0;
        
        ArrayInitialize(slice, 0.0);
        ArrayInitialize(PriceBuffer, 0.0);
        PriceBuffer[prev_calculated] = close[prev_calculated];
    }
    
    int i = prev_calculated;
    
    if (offline) {
        for (; i < rates_total - 1 && !IsStopped(); i++) {
            if (slice[2] == close[i]) {
                continue;
            }
            
            slice[0] = slice[1];
            slice[1] = slice[2];
            slice[2] = close[i];
            
            if (IsPeakNode(slice[0], slice[1], slice[2])) {
                type = Peak;
                PriceBuffer[i - 1] = slice[1];
                continue;
            }
            
            if (IsBottomNode(slice[0], slice[1], slice[2])) {
                type = Bottom;
                PriceBuffer[i - 1] = slice[1];
            }
        }  
        current_dt = iTime(Symbol(), Period(), 0);
        offline = false;
        return i;
    }
    
    if (!BarEvent()) {
        switch (type) {
            case Peak:
                PriceBuffer[i - 1] = close[i - 1] < close[i] ? close[i - 1] : 0.0;
                break;
            case Bottom:
                PriceBuffer[i - 1] = close[i - 1] > close[i] ? close[i - 1] : 0.0;
                break;
        }
        return prev_calculated;
    }

    if (slice[2] == close[i]) {
        PriceBuffer[i - 1] = 0.0;
        return i + 1;
    }
    
    slice[0] = slice[1];
    slice[1] = slice[2];
    slice[2] = close[i];
    
    if (IsPeakNode(slice[0], slice[1], slice[2])) {
        type = Peak;
        PriceBuffer[i - 1] = slice[1];
        return i + 1;
    }
    
    if (IsBottomNode(slice[0], slice[1], slice[2])) {
        type = Bottom;
        PriceBuffer[i - 1] = slice[1];
        return i + 1;
    }
    
    PriceBuffer[i - 1] = 0.0;

//--- return value of prev_calculated for next call
    return i + 1;
}
//+------------------------------------------------------------------+
bool BarEvent(void) {
    if (iTime(Symbol(), Period(), 0) > current_dt) {
        current_dt = iTime(Symbol(), Period(), 0);
        return true;
    }
    return false;
}
//+------------------------------------------------------------------+
bool IsBottomNode(double prev, double current, double next) {
    return prev > current && next > current;
}
//+------------------------------------------------------------------+
bool IsPeakNode(double prev, double current, double next) {
    return prev < current && next < current;
}