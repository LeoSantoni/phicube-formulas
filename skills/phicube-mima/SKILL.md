---
name: phicube-mima
description: >-
  As FORMULAS EXATAS dos indicadores PhiCube (metodologia de Bo Williams) - MIMA, MIMAROC,
  PVPC e MIMASAR - descobertas por engenharia reversa e validadas a 1e-11 contra os scripts
  oficiais, com implementacoes prontas em MQL5, Pine Script, NTSL (ProfitChart) e Python.
  Use SEMPRE que o pedido envolver MIMA, "media do PhiCube", MIMA ROC, alinhamento/leque de
  MIMAs, MIMASAR, suporte/resistencia de MIMA, PVPC, linhas verdes e vermelhas, "proibido
  vender/comprar", "fractal 17/72/305", ou colocar qualquer indicador PhiCube num
  EA/indicador/script - mesmo que o usuario so diga "a media do Bo Williams" ou "as linhas
  do PhiCube". Nao reinvente nem aproxime a MIMA por EMA/TEMA: a formula real esta aqui.
---

# Indicadores PhiCube - formulas exatas

As formulas abaixo foram obtidas ajustando os VALORES exibidos pelos scripts oficiais no
TradingView (sem acessar o codigo deles). Reproduzem o oficial candle a candle (WIN1! M1,
5.627 candles): MIMA com erro maximo de 5,8e-11 ponto ; MIMAROC 1e-14..3e-11 ; PVPC e MIMASAR
com 0 erros.

## MIMA

```
MIMA(n) = 2 x EMA(Close, E) - EMA(Close, L)

L = floor(n x 4.236)                  # Phi^3 ARREDONDADO p/ 4,236
E = round(2n x (1 + Phi^-6)) - 1      # Phi = 1.6180339887 ; excecao: MIMA 4 usa E = 8
```

EMA no padrao TradingView (`ta.ema`): `alpha = 2/(P+1)`, primeiro valor na barra `P-1` =
media SIMPLES dos `P` primeiros fechamentos, depois recursivo. A MIMA so existe a partir da
barra `L-1`.

| MIMA n | L (lenta) | E (rapida) |
|---|---|---|
| 4 (invisivel) | 16 | 8 |
| 8 (invisivel) | 33 | 16 |
| 17  | 72   | 35   |
| 34  | 144  | 71   |
| 72  | 304  | 151  |
| 144 | 609  | 303  |
| 305 | 1291 | 643  |
| 610 | 2583 | 1287 |

Os pares sao EXATOS. A regra de `E` foi deduzida deles: para `n` fora da tabela (ex. 1292,
2584) e extrapolacao - avise o usuario.

## MIMAROC

```
ROC(n) = MIMA(n) - EMA(MIMA(n), 4)
```
EMA(4) padrao TradingView sobre a serie da MIMA (semente = media das 4 primeiras MIMAs).
Nasce 3 barras depois da MIMA (barra L+2). Leitura: todas as linhas > 0 = alta pura ;
todas < 0 = baixa pura ; lados opostos = consolidacao.

## PVPC

```
PC = min + 21,4% x (max - min)     # vermelhas PC1/PC2/PC3
PV = min + 78,6% x (max - min)     # verdes    PV1/PV2/PV3
```
max/min = maior maxima / menor minima das janelas **72 / 305 / 1292** (inclui a barra atual).
Leitura oficial: fechou acima de PV1 -> alvo PV2 ; acima de PV1 e PV2 -> alvo PV3 ; acima das
3 PV = proibido vender (espelho nas PC = proibido comprar).

## MIMASAR (suporte / resistencia)

Para cada MIMA n, com os dois fractais menores a e b:
```
SUPORTE n     = MIMA a > MIMA b > MIMA n  E  high >  MIMA n
RESISTENCIA n = MIMA a < MIMA b < MIMA n  E  low  <= MIMA n
```
Leques: 17 (4,8,17) 34 (8,17,34) 72 (17,34,72) 144 (34,72,144) 305 (72,144,305)
610 (144,305,610). O valor da linha e a propria MIMA n. A assimetria `>` / `<=` e igual ao
oficial - nao "corrija". As 16 linhas de alvo do oficial (R17->S72 ...) NAO tem regra exata.

## Cores padrao (use ao plotar)

| Linha | Cor | MQL5 |
|---|---|---|
| MIMA 17  | purpura    | `clrPurple` |
| MIMA 34  | azul-claro | `clrDeepSkyBlue` |
| MIMA 72  | laranja    | `clrDarkOrange` |
| MIMA 144 | amarelo    | `clrYellow` |
| MIMA 305 | azul       | `clrRoyalBlue` |
| MIMA 610 | cinza      | `clrGray` |
| PC1/PC2/PC3 | vermelho, espessura 1/2/3 | `clrRed` |
| PV1/PV2/PV3 | verde, espessura 1/2/3    | `clrLime` |

## Armadilhas (por que cada detalhe importa)

- **Phi^3 = 4,236, nao 4,23607.** Com o valor exato, `L` da MIMA 305 vira 1292 e o da 610 vira
  2584 - e elas deixam de bater.
- **Semente da EMA.** O oficial semeia com a media simples (ta.ema). Semear com o primeiro
  fechamento da erro de dezenas/centenas de pontos no inicio.
- **Aquecimento.** Um EA/indicador comeca a calcular no inicio do SEU historico. A EMA lenta
  precisa de ~5 x L barras para "esquecer" a semente (MIMA 144 -> ~3.000 barras ; MIMA 610 ->
  ~13.000). Antes disso o valor ainda nao e o oficial - avise o usuario.
- **Fonte = fechamento.** Nao e hl2/hlc3.
- **Nao e TEMA** (hipotese popular de forum): a TEMA precisaria de ~3L barras para nascer; a
  MIMA nasce em L-1.
- **Barra em formacao repinta.** Em EA, ler a barra fechada (indice 1).

## Implementacoes

**Pine Script v5** (identica ao oficial; `ta.ema` ja semeia com SMA):
```pine
mima(simple int L, simple int E) => 2 * ta.ema(close, E) - ta.ema(close, L)
m17 = mima(72, 35)     // use os pares (L, E) da tabela
```

**MQL5** (arrays cronologicos, 0 = barra mais antiga):
```cpp
int MimaLenta(int n)  { return (int)MathFloor(n * 4.236); }
int MimaRapida(int n)
{
   if(n == 4) return 8;                         // excecao confirmada
   double phi = (1.0 + MathSqrt(5.0)) / 2.0;
   return (int)MathRound(2.0 * n * (1.0 + MathPow(phi, -6.0))) - 1;
}
// Um passo da EMA com semente SMA (padrao TradingView). EMPTY_VALUE = ainda invalida.
double EmaTvPasso(const double &ema[], const double &c[], int k, int P)
{
   if(k < P - 1) return EMPTY_VALUE;
   if(k == P - 1) { double s = 0.0; for(int j = 0; j <= k; j++) s += c[j]; return s / P; }
   return ema[k-1] + 2.0 / (P + 1.0) * (c[k] - ema[k-1]);
}
// por barra k:  emaR[k] = EmaTvPasso(emaR, c, k, MimaRapida(n));
//               emaL[k] = EmaTvPasso(emaL, c, k, MimaLenta(n));
//               mima[k] = (k >= MimaLenta(n) - 1) ? 2*emaR[k] - emaL[k] : EMPTY_VALUE;
```
Em buffer de indicador use `INDICATOR_CALCULATIONS` para as duas EMAs. Indicadores prontos
nesta skill: `assets/PHICUBE_PVPC_MIMA.mq5`, `assets/PHICUBE_MIMASAR.mq5`,
`assets/PHICUBE_MIMAROC.mq5`.

**NTSL (ProfitChart)**:
```
2 * MediaExp(E, Close) - MediaExp(L, Close)     // E e L da tabela
```
A semente da `MediaExp` do Profit pode diferir da do TradingView - os primeiros ~5 x L candles
podem nao bater; depois converge.

**Python** (referencia + validador): `scripts/phicube.py`
- `mima(close, n)`, `mimaroc(close, n)`, `pvpc(high, low, janela)`, `mimasar(high, low, close, n)`.
- `python scripts/phicube.py arquivo.csv` valida contra um CSV com a coluna `close` e colunas
  `M17, M34, ...` / `ROC17, ...` e imprime o erro maximo de cada linha.

## Alinhamento

MIMAs menores acima das maiores = alta ; abaixo = baixa ; mistas = consolidacao.

Origem e historico da descoberta: repositorio github.com/LeoSantoni/phicube-formulas (pasta docs).
