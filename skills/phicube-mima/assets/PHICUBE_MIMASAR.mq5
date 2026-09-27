//+------------------------------------------------------------------------+
//|                          PHICUBE MIMASAR.mq5                            |
//|  Suporte / Resistencia das MIMAs PhiCube (MIMASAR = MIMA Suporte e      |
//|  Resistencia) - REGRA EXATA, reconstruida a partir dos valores do       |
//|  "PhiCube MIMASAR" oficial (TradingView, WIN1! M1, 5.627 barras,        |
//|  26/09/2026): 0 erros nas 12 linhas de suporte/resistencia.             |
//|  Detalhes: docs/mimasar.md                                              |
//|                                                                        |
//|  Para cada MIMA n, com a = n/4,236^2 e b = n/4,236 (fractais menores):  |
//|    SUPORTE n     = leque de alta  MIMA a > MIMA b > MIMA n              |
//|                    e maxima > MIMA n                                    |
//|    RESISTENCIA n = leque de baixa MIMA a < MIMA b < MIMA n              |
//|                    e minima <= MIMA n                                   |
//|  Leques: 17 (4,8,17) 34 (8,17,34) 72 (17,34,72) 144 (34,72,144)         |
//|          305 (72,144,305) 610 (144,305,610)                             |
//|  MIMAs "invisiveis": MIMA 4 = 2.EMA(8) - EMA(16) ;                      |
//|                     MIMA 8 = 2.EMA(16) - EMA(33)   (confirmadas).       |
//|                                                                        |
//|  Suporte E resistencia = LINHA CHEIA (DRAW_LINE) na cor da MIMA, um    |
//|  pouco mais grossa que a MIMA do PHICUBE_PVPC_MIMA (1/1/2/2/3/3):      |
//|  largura 3/3/4/4/5/5 (17/34/72/144/305/610). Sem marcadores, sem       |
//|  pontilhado. O valor plotado e o da propria MIMA.                      |
//|  Ainda sem as 16 linhas de alvo do oficial (R17->S72 etc.).             |
//|  AQUECIMENTO: a MIMA 610 (e a decisao S/R 305/610) so estabiliza apos   |
//|  ~13.000 barras (5 x L) -> manter "Max. barras no grafico" alto.        |
//|  A assimetria high > / low <= e intencional (igual ao oficial).        |
//|  A barra corrente repinta: EAs devem ler a barra 1 (fechada).          |
//|  v2.01: desenho comeca em L-1 (primeira barra valida, igual ao TV).    |
//|  v2.02: SO VISUAL (usuario nao via o SAR sob a MIMA de mesma cor):     |
//|         suporte = traco grosso ; resistencia = marcadores "x".         |
//|         Calculo identico ao da v2.01 (regra exata, validada).          |
//|  v2.03: SO VISUAL (pedido: "SAR apenas mais grosso"): suporte e        |
//|         resistencia = linha cheia na cor da MIMA, largura 3/3/4/4/5/5. |
//|         Removidos os "x" e o traco extra-grosso. Calculo inalterado.   |
//+------------------------------------------------------------------------+
#property copyright   "PHICUBE"
#property version     "2.03"
#property description "PhiCube MIMASAR v2.03 - suporte/resistencia das MIMAs pela regra exata do oficial (leque + toque)."
#property indicator_chart_window
#property indicator_buffers 36
#property indicator_plots   12

// 1-12: suporte E resistencia = LINHA CHEIA na cor da MIMA, largura 3/3/4/4/5/5
//       (a MIMA do PVPC_MIMA tem 1/1/2/2/3/3 -> o SAR fica so um pouco mais grosso)
#property indicator_label1  "Suporte 17"
#property indicator_type1   DRAW_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrPurple
#property indicator_width1  3
#property indicator_label2  "Suporte 34"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_color2  clrDeepSkyBlue
#property indicator_width2  3
#property indicator_label3  "Suporte 72"
#property indicator_type3   DRAW_LINE
#property indicator_style3  STYLE_SOLID
#property indicator_color3  clrDarkOrange
#property indicator_width3  4
#property indicator_label4  "Suporte 144"
#property indicator_type4   DRAW_LINE
#property indicator_style4  STYLE_SOLID
#property indicator_color4  clrYellow
#property indicator_width4  4
#property indicator_label5  "Suporte 305"
#property indicator_type5   DRAW_LINE
#property indicator_style5  STYLE_SOLID
#property indicator_color5  clrRoyalBlue
#property indicator_width5  5
#property indicator_label6  "Suporte 610"
#property indicator_type6   DRAW_LINE
#property indicator_style6  STYLE_SOLID
#property indicator_color6  clrGray
#property indicator_width6  5
#property indicator_label7  "Resistencia 17"
#property indicator_type7   DRAW_LINE
#property indicator_style7  STYLE_SOLID
#property indicator_color7  clrPurple
#property indicator_width7  3
#property indicator_label8  "Resistencia 34"
#property indicator_type8   DRAW_LINE
#property indicator_style8  STYLE_SOLID
#property indicator_color8  clrDeepSkyBlue
#property indicator_width8  3
#property indicator_label9  "Resistencia 72"
#property indicator_type9   DRAW_LINE
#property indicator_style9  STYLE_SOLID
#property indicator_color9  clrDarkOrange
#property indicator_width9  4
#property indicator_label10 "Resistencia 144"
#property indicator_type10  DRAW_LINE
#property indicator_style10 STYLE_SOLID
#property indicator_color10 clrYellow
#property indicator_width10 4
#property indicator_label11 "Resistencia 305"
#property indicator_type11  DRAW_LINE
#property indicator_style11 STYLE_SOLID
#property indicator_color11 clrRoyalBlue
#property indicator_width11 5
#property indicator_label12 "Resistencia 610"
#property indicator_type12  DRAW_LINE
#property indicator_style12 STYLE_SOLID
#property indicator_color12 clrGray
#property indicator_width12 5


// MIMAs calculadas: indice 0..7 = 4, 8, 17, 34, 72, 144, 305, 610
const int MIMA_N[8] = {4, 8, 17, 34, 72, 144, 305, 610};
const int MIMA_L[8] = {16, 33, 72, 144, 304, 609, 1291, 2583};   // EMA lenta
const int MIMA_E[8] = {8,  16, 35,  71, 151, 303,  643, 1287};   // EMA rapida

double bS0[], bS1[], bS2[], bS3[], bS4[], bS5[];   // suportes 17..610
double bR0[], bR1[], bR2[], bR3[], bR4[], bR5[];   // resistencias 17..610
double eR0[], eL0[], mM0[], eR1[], eL1[], mM1[], eR2[], eL2[], mM2[], eR3[], eL3[], mM3[];
double eR4[], eL4[], mM4[], eR5[], eL5[], mM5[], eR6[], eL6[], mM6[], eR7[], eL7[], mM7[];

// EMA padrao TradingView (semente = media simples dos P primeiros).
double EmaTv(const double &ema[], const double &x[], int k, int P)
{
   if(k < P - 1) return EMPTY_VALUE;
   if(k == P - 1)
   {
      double s = 0.0;
      for(int j = 0; j <= k; j++) s += x[j];
      return s / P;
   }
   return ema[k-1] + 2.0 / (P + 1.0) * (x[k] - ema[k-1]);
}

double MimaEm(double &eR[], double &eL[], const double &close[], int k, int i)
{
   eR[k] = EmaTv(eR, close, k, MIMA_E[i]);
   eL[k] = EmaTv(eL, close, k, MIMA_L[i]);
   return (k >= MIMA_L[i] - 1) ? 2.0 * eR[k] - eL[k] : EMPTY_VALUE;
}

// Suporte/resistencia da MIMA n (mn) com leque (ma, mb, mn).
void Linha(double &bS[], double &bR[], double ma, double mb, double mn,
           double hi, double lo, int k)
{
   bS[k] = EMPTY_VALUE; bR[k] = EMPTY_VALUE;
   if(ma == EMPTY_VALUE || mb == EMPTY_VALUE || mn == EMPTY_VALUE) return;
   if(ma > mb && mb > mn && hi > mn)  bS[k] = mn;   // leque de alta + toque
   if(ma < mb && mb < mn && lo <= mn) bR[k] = mn;   // leque de baixa + toque
}

int OnInit()
{
   SetIndexBuffer(0,  bS0, INDICATOR_DATA); SetIndexBuffer(1,  bS1, INDICATOR_DATA);
   SetIndexBuffer(2,  bS2, INDICATOR_DATA); SetIndexBuffer(3,  bS3, INDICATOR_DATA);
   SetIndexBuffer(4,  bS4, INDICATOR_DATA); SetIndexBuffer(5,  bS5, INDICATOR_DATA);
   SetIndexBuffer(6,  bR0, INDICATOR_DATA); SetIndexBuffer(7,  bR1, INDICATOR_DATA);
   SetIndexBuffer(8,  bR2, INDICATOR_DATA); SetIndexBuffer(9,  bR3, INDICATOR_DATA);
   SetIndexBuffer(10, bR4, INDICATOR_DATA); SetIndexBuffer(11, bR5, INDICATOR_DATA);
   int b = 12;
   SetIndexBuffer(b++, eR0, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL0, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM0, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR1, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL1, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR2, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL2, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR3, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL3, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR4, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL4, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM4, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR5, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL5, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM5, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR6, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL6, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM6, INDICATOR_CALCULATIONS);
   SetIndexBuffer(b++, eR7, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, eL7, INDICATOR_CALCULATIONS); SetIndexBuffer(b++, mM7, INDICATOR_CALCULATIONS);

   for(int p = 0; p < 12; p++)
   {
      PlotIndexSetDouble (p, PLOT_EMPTY_VALUE, EMPTY_VALUE);
      PlotIndexSetInteger(p, PLOT_DRAW_BEGIN, MIMA_L[2 + p % 6] - 1);
   }
   IndicatorSetString(INDICATOR_SHORTNAME, "PHICUBE MIMASAR");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   if(rates_total < 2) return 0;
   ArraySetAsSeries(close, false);   // cronologico: 0 = barra mais antiga
   ArraySetAsSeries(high,  false);
   ArraySetAsSeries(low,   false);

   int ini = (prev_calculated > 1 ? prev_calculated - 1 : 0);   // recalcula a barra em formacao
   for(int k = ini; k < rates_total; k++)
   {
      mM0[k] = MimaEm(eR0, eL0, close, k, 0);   // 4
      mM1[k] = MimaEm(eR1, eL1, close, k, 1);   // 8
      mM2[k] = MimaEm(eR2, eL2, close, k, 2);   // 17
      mM3[k] = MimaEm(eR3, eL3, close, k, 3);   // 34
      mM4[k] = MimaEm(eR4, eL4, close, k, 4);   // 72
      mM5[k] = MimaEm(eR5, eL5, close, k, 5);   // 144
      mM6[k] = MimaEm(eR6, eL6, close, k, 6);   // 305
      mM7[k] = MimaEm(eR7, eL7, close, k, 7);   // 610

      Linha(bS0, bR0, mM0[k], mM1[k], mM2[k], high[k], low[k], k);   // 17  (4, 8, 17)
      Linha(bS1, bR1, mM1[k], mM2[k], mM3[k], high[k], low[k], k);   // 34  (8, 17, 34)
      Linha(bS2, bR2, mM2[k], mM3[k], mM4[k], high[k], low[k], k);   // 72  (17, 34, 72)
      Linha(bS3, bR3, mM3[k], mM4[k], mM5[k], high[k], low[k], k);   // 144 (34, 72, 144)
      Linha(bS4, bR4, mM4[k], mM5[k], mM6[k], high[k], low[k], k);   // 305 (72, 144, 305)
      Linha(bS5, bR5, mM5[k], mM6[k], mM7[k], high[k], low[k], k);   // 610 (144, 305, 610)
   }
   return rates_total;
}
