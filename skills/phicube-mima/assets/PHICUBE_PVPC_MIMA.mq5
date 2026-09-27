//+------------------------------------------------------------------------+
//|                        PHICUBE PVPC MIMA.mq5                            |
//|  Indicador (janela do preco) com as linhas da metodologia PhiCube:      |
//|                                                                        |
//|  PVPC - 6 linhas (validadas 100% contra o PVPC oficial no TradingView):|
//|    para N = 72 / 305 / 1292 barras, max/min = maior maxima / menor     |
//|    minima da janela (incluindo a barra atual):                          |
//|      PC = min + 21,4% x (max - min)      (vermelho, espessura 1/2/3)    |
//|      PV = min + 78,6% x (max - min)      (verde,    espessura 1/2/3)    |
//|                                                                        |
//|  MIMAs 17 / 34 / 72 / 144 / 305 / 610 - FORMULA EXATA (descoberta em    |
//|  25/09/2026, erro 5,8e-11 vs o script oficial "PhiCube MIMASAR"):       |
//|      MIMA(n) = 2 x EMA(fechamento, E) - EMA(fechamento, L)              |
//|      L = floor(n x 4,236)   (Phi^3 ARREDONDADO)                         |
//|      E = round(2n x (1 + Phi^-6)) - 1                                   |
//|      EMA padrao TradingView: alpha 2/(P+1), semente = media simples     |
//|      dos P primeiros fechamentos. A MIMA nasce na barra L-1.            |
//|    Pares (L,E): 17->(72,35) 34->(144,71) 72->(304,151) 144->(609,303)   |
//|                 305->(1291,643) 610->(2583,1287)                        |
//|                                                                        |
//|  Aquecimento: o indicador calcula desde a 1a barra do historico do      |
//|  grafico. A EMA lenta precisa de ~5 x L barras para "esquecer" a        |
//|  semente - com historico curto as MIMAs longas (305/610) ainda nao      |
//|  batem com o oficial nas primeiras barras (aumente "Max barras no       |
//|  grafico" em Ferramentas > Opcoes > Graficos se precisar).              |
//+------------------------------------------------------------------------+
#property copyright   "PHICUBE"
#property version     "1.01"
#property description "PhiCube - PVPC (6 linhas) + MIMAs 17/34/72/144/305/610 com a formula exata."
#property indicator_chart_window
#property indicator_buffers 24
#property indicator_plots   12

//--- PVPC (mesmas cores/espessuras do NTSL original: PC vermelho, PV verde)
#property indicator_label1  "PC1 (72)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_width1  1
#property indicator_label2  "PC2 (305)"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  2
#property indicator_label3  "PC3 (1292)"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_width3  3
#property indicator_label4  "PV1 (72)"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrLime
#property indicator_width4  1
#property indicator_label5  "PV2 (305)"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrLime
#property indicator_width5  2
#property indicator_label6  "PV3 (1292)"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrLime
#property indicator_width6  3

//--- MIMAs (uma cor por fractal)
#property indicator_label7  "MIMA 17"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrPurple
#property indicator_width7  1
#property indicator_label8  "MIMA 34"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrDeepSkyBlue
#property indicator_width8  1
#property indicator_label9  "MIMA 72"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrDarkOrange
#property indicator_width9  2
#property indicator_label10 "MIMA 144"
#property indicator_type10  DRAW_LINE
#property indicator_color10 clrYellow
#property indicator_width10 2
#property indicator_label11 "MIMA 305"
#property indicator_type11  DRAW_LINE
#property indicator_color11 clrRoyalBlue
#property indicator_width11 3
#property indicator_label12 "MIMA 610"
#property indicator_type12  DRAW_LINE
#property indicator_color12 clrGray
#property indicator_width12 3

input bool Mostrar_PVPC  = true;   // Mostrar as 6 linhas do PVPC
input bool Mostrar_MIMAs = true;   // Mostrar as 6 MIMAs

// plots
double bPC1[], bPC2[], bPC3[], bPV1[], bPV2[], bPV3[];
double bM17[], bM34[], bM72[], bM144[], bM305[], bM610[];
// EMAs das MIMAs (calculo): rapida e lenta de cada uma
double eR17[], eL17[], eR34[], eL34[], eR72[], eL72[];
double eR144[], eL144[], eR305[], eL305[], eR610[], eL610[];

const int PVPC_N[3] = {72, 305, 1292};
const int MIMA_N[6] = {17, 34, 72, 144, 305, 610};

int MimaLenta(int n)  { return (int)MathFloor(n * 4.236); }
int MimaRapida(int n)
{
   double phi = (1.0 + MathSqrt(5.0)) / 2.0;
   return (int)MathRound(2.0 * n * (1.0 + MathPow(phi, -6.0))) - 1;
}

// EMA padrao TradingView (semente = media simples dos P primeiros). 0 = invalida.
double EmaTv(const double &ema[], const double &x[], int k, int P)
{
   if(k < P - 1) return 0.0;
   if(k == P - 1) { double s = 0.0; for(int j = 0; j <= k; j++) s += x[j]; return s / P; }
   return ema[k-1] + 2.0 / (P + 1.0) * (x[k] - ema[k-1]);
}

// Uma MIMA na barra k (EMPTY_VALUE antes de nascer).
double MimaEm(double &eR[], double &eL[], const double &close[], int k, int n)
{
   int L = MimaLenta(n), E = MimaRapida(n);
   eR[k] = EmaTv(eR, close, k, E);
   eL[k] = EmaTv(eL, close, k, L);
   return (k >= L - 1) ? 2.0 * eR[k] - eL[k] : EMPTY_VALUE;
}

int OnInit()
{
   SetIndexBuffer(0,  bPC1, INDICATOR_DATA);
   SetIndexBuffer(1,  bPC2, INDICATOR_DATA);
   SetIndexBuffer(2,  bPC3, INDICATOR_DATA);
   SetIndexBuffer(3,  bPV1, INDICATOR_DATA);
   SetIndexBuffer(4,  bPV2, INDICATOR_DATA);
   SetIndexBuffer(5,  bPV3, INDICATOR_DATA);
   SetIndexBuffer(6,  bM17,  INDICATOR_DATA);
   SetIndexBuffer(7,  bM34,  INDICATOR_DATA);
   SetIndexBuffer(8,  bM72,  INDICATOR_DATA);
   SetIndexBuffer(9,  bM144, INDICATOR_DATA);
   SetIndexBuffer(10, bM305, INDICATOR_DATA);
   SetIndexBuffer(11, bM610, INDICATOR_DATA);
   SetIndexBuffer(12, eR17,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, eL17,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, eR34,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(15, eL34,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(16, eR72,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(17, eL72,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(18, eR144, INDICATOR_CALCULATIONS);
   SetIndexBuffer(19, eL144, INDICATOR_CALCULATIONS);
   SetIndexBuffer(20, eR305, INDICATOR_CALCULATIONS);
   SetIndexBuffer(21, eL305, INDICATOR_CALCULATIONS);
   SetIndexBuffer(22, eR610, INDICATOR_CALCULATIONS);
   SetIndexBuffer(23, eL610, INDICATOR_CALCULATIONS);

   for(int p = 0; p < 12; p++) PlotIndexSetDouble(p, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   for(int j = 0; j < 3; j++)
   {
      PlotIndexSetInteger(j,     PLOT_DRAW_BEGIN, PVPC_N[j] - 1);
      PlotIndexSetInteger(j + 3, PLOT_DRAW_BEGIN, PVPC_N[j] - 1);
   }
   for(int j = 0; j < 6; j++) PlotIndexSetInteger(6 + j, PLOT_DRAW_BEGIN, MimaLenta(MIMA_N[j]) - 1);

   // mostrar/ocultar: o indicador e so visual, entao o liga/desliga e so de desenho
   for(int p = 0; p < 6; p++)  PlotIndexSetInteger(p,     PLOT_DRAW_TYPE, Mostrar_PVPC  ? DRAW_LINE : DRAW_NONE);
   for(int p = 6; p < 12; p++) PlotIndexSetInteger(p,     PLOT_DRAW_TYPE, Mostrar_MIMAs ? DRAW_LINE : DRAW_NONE);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString (INDICATOR_SHORTNAME, "PHICUBE PVPC + MIMAs");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   if(rates_total < 2) return 0;
   // indexacao cronologica (0 = barra mais antiga)
   ArraySetAsSeries(high, false); ArraySetAsSeries(low, false); ArraySetAsSeries(close, false);

   int ini = (prev_calculated > 1 ? prev_calculated - 1 : 0);   // recalcula a barra em formacao

   for(int k = ini; k < rates_total; k++)
   {
      //--- PVPC
      double pc[3], pv[3];
      for(int j = 0; j < 3; j++)
      {
         int N = PVPC_N[j];
         if(k < N - 1) { pc[j] = EMPTY_VALUE; pv[j] = EMPTY_VALUE; continue; }
         double mx = high[ArrayMaximum(high, k - N + 1, N)];
         double mn = low [ArrayMinimum(low,  k - N + 1, N)];
         double rg = mx - mn;
         pc[j] = rg * 0.214 + mn;
         pv[j] = rg * 0.786 + mn;
      }
      bPC1[k] = pc[0]; bPC2[k] = pc[1]; bPC3[k] = pc[2];
      bPV1[k] = pv[0]; bPV2[k] = pv[1]; bPV3[k] = pv[2];

      //--- MIMAs (sempre calculadas - as EMAs precisam de continuidade)
      bM17[k]  = MimaEm(eR17,  eL17,  close, k, 17);
      bM34[k]  = MimaEm(eR34,  eL34,  close, k, 34);
      bM72[k]  = MimaEm(eR72,  eL72,  close, k, 72);
      bM144[k] = MimaEm(eR144, eL144, close, k, 144);
      bM305[k] = MimaEm(eR305, eL305, close, k, 305);
      bM610[k] = MimaEm(eR610, eL610, close, k, 610);
   }
   return rates_total;
}
