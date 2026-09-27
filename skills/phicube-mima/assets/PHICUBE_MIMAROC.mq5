//+------------------------------------------------------------------------+
//|                          PHICUBE MIMAROC.mq5                            |
//|  Subjanela com os 6 ROCs das MIMAs PhiCube - FORMULA EXATA (descoberta  |
//|  em 26/09/2026, erro 1e-14..3e-11 vs o "PhiCube MIMAROC Suite" oficial):|
//|                                                                        |
//|      ROC(n) = MIMA(n) - EMA(MIMA(n), 4)                                 |
//|      MIMA(n) = 2 x EMA(fechamento, E) - EMA(fechamento, L)              |
//|      L = floor(n x 4,236) ; E = round(2n x (1 + Phi^-6)) - 1            |
//|      EMAs no padrao TradingView: alpha 2/(P+1), semente = media simples |
//|      dos P primeiros valores. O ROC nasce 3 barras depois da MIMA.      |
//|                                                                        |
//|  Leitura oficial: todas as linhas > 0 = tendencia pura de alta ;        |
//|  todas < 0 = pura de baixa ; lados opostos do zero = consolidacao ;     |
//|  observar o LEQUE (linhas alinhadas em sequencia) e divergencias.       |
//|  Cores = paleta das MIMAs (skills/phicube-mima). Usar junto com o        |
//|  PHICUBE_PVPC_MIMA (janela do preco).                                   |
//|  AQUECIMENTO: ROC 610 so bate com o oficial apos ~13.000 barras.        |
//|  v1.01: casas decimais seguem o ativo (_Digits).                        |
//+------------------------------------------------------------------------+
#property copyright   "PHICUBE"
#property version     "1.01"
#property description "PhiCube MIMAROC - ROC 17/34/72/144/305/610 com a formula exata (MIMA - EMA4 da MIMA)."
#property indicator_separate_window
#property indicator_buffers 30
#property indicator_plots   6
#property indicator_level1  0.0
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT

#property indicator_label1  "ROC 17"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrPurple
#property indicator_width1  1
#property indicator_label2  "ROC 34"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDeepSkyBlue
#property indicator_width2  1
#property indicator_label3  "ROC 72"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkOrange
#property indicator_width3  2
#property indicator_label4  "ROC 144"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrYellow
#property indicator_width4  2
#property indicator_label5  "ROC 305"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRoyalBlue
#property indicator_width5  3
#property indicator_label6  "ROC 610"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrGray
#property indicator_width6  3

const int MIMA_N[6] = {17, 34, 72, 144, 305, 610};

// plots
double bR17[], bR34[], bR72[], bR144[], bR305[], bR610[];
// calculo, por fractal: EMA rapida, EMA lenta, MIMA, EMA4 da MIMA
double eR17[],  eL17[],  m17[],  q17[];
double eR34[],  eL34[],  m34[],  q34[];
double eR72[],  eL72[],  m72[],  q72[];
double eR144[], eL144[], m144[], q144[];
double eR305[], eL305[], m305[], q305[];
double eR610[], eL610[], m610[], q610[];

int MimaLenta(int n)  { return (int)MathFloor(n * 4.236); }
int MimaRapida(int n)
{
   double phi = (1.0 + MathSqrt(5.0)) / 2.0;
   return (int)MathRound(2.0 * n * (1.0 + MathPow(phi, -6.0))) - 1;
}

// EMA padrao TradingView de x com periodo P, sobre a serie que comeca
// (e valida) na barra 'ini'. Semente = media simples de x[ini..ini+P-1].
// Devolve EMPTY_VALUE enquanto nao ha P valores.
double EmaTvDe(const double &ema[], const double &x[], int k, int P, int ini)
{
   if(k < ini + P - 1) return EMPTY_VALUE;
   if(k == ini + P - 1)
   {
      double s = 0.0;
      for(int j = ini; j <= k; j++) s += x[j];
      return s / P;
   }
   return ema[k-1] + 2.0 / (P + 1.0) * (x[k] - ema[k-1]);
}

// ROC n na barra k (preenche as series intermediarias).
double RocEm(double &eR[], double &eL[], double &m[], double &q[],
             const double &close[], int k, int n)
{
   int L = MimaLenta(n), E = MimaRapida(n);
   eR[k] = EmaTvDe(eR, close, k, E, 0);
   eL[k] = EmaTvDe(eL, close, k, L, 0);
   if(k < L - 1) { m[k] = EMPTY_VALUE; q[k] = EMPTY_VALUE; return EMPTY_VALUE; }
   m[k] = 2.0 * eR[k] - eL[k];                       // MIMA (nasce em L-1)
   q[k] = EmaTvDe(q, m, k, 4, L - 1);                // EMA(MIMA, 4)
   return (q[k] == EMPTY_VALUE) ? EMPTY_VALUE : m[k] - q[k];
}

int OnInit()
{
   SetIndexBuffer(0, bR17,  INDICATOR_DATA);
   SetIndexBuffer(1, bR34,  INDICATOR_DATA);
   SetIndexBuffer(2, bR72,  INDICATOR_DATA);
   SetIndexBuffer(3, bR144, INDICATOR_DATA);
   SetIndexBuffer(4, bR305, INDICATOR_DATA);
   SetIndexBuffer(5, bR610, INDICATOR_DATA);
   int b = 6;
   SetIndexBuffer(b++, eR17,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL17,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m17,   INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q17,   INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR34,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL34,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m34,   INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q34,   INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR72,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL72,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m72,   INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q72,   INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR144, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL144, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m144,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q144,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR305, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL305, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m305,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q305,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR610, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL610, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, m610,  INDICATOR_CALCULATIONS); SetIndexBuffer(b++, q610,  INDICATOR_CALCULATIONS);

   for(int p = 0; p < 6; p++)
   {
      PlotIndexSetDouble (p, PLOT_EMPTY_VALUE, EMPTY_VALUE);
      PlotIndexSetInteger(p, PLOT_DRAW_BEGIN,  MimaLenta(MIMA_N[p]) + 2);   // ROC nasce em L+2
   }
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString (INDICATOR_SHORTNAME, "PHICUBE MIMAROC");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   if(rates_total < 2) return 0;
   ArraySetAsSeries(close, false);   // cronologico: 0 = barra mais antiga

   int ini = (prev_calculated > 1 ? prev_calculated - 1 : 0);   // recalcula a barra em formacao
   for(int k = ini; k < rates_total; k++)
   {
      bR17[k]  = RocEm(eR17,  eL17,  m17,  q17,  close, k, 17);
      bR34[k]  = RocEm(eR34,  eL34,  m34,  q34,  close, k, 34);
      bR72[k]  = RocEm(eR72,  eL72,  m72,  q72,  close, k, 72);
      bR144[k] = RocEm(eR144, eL144, m144, q144, close, k, 144);
      bR305[k] = RocEm(eR305, eL305, m305, q305, close, k, 305);
      bR610[k] = RocEm(eR610, eL610, m610, q610, close, k, 610);
   }
   return rates_total;
}
