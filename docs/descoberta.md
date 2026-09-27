# Descoberta da MIMA, do MIMAROC e confirmação do PVPC

Feito pelo Claude (Anthropic) no Claude Code, entre 25 e 26/09/2026.

## Ponto de partida: o que se sabia

A MIMA é descrita publicamente só como "média móvel mais rápida, com menos sinais falsos". Não havia
fórmula pública. As hipóteses que circulavam:

| Hipótese | Origem | Resultado |
|---|---|---|
| MIMA(n) ≈ TEMA(n × Φ³) | fórum MQL5 | **Errada**, mas o "n × Φ³" estava certo |
| MIMA ≈ EMA do mesmo período | fórum MQL5 | Errada |
| Alligator / fractais de Bill Williams | repositórios no GitHub | Proxy, não é a MIMA |
| EMAs 17…2584 no lugar da MIMA | scripts de comunidade no TradingView | Aproximação declarada |

Uma busca no código público do GitHub (419 arquivos com "phicube") não achou nenhuma MIMA real. Só
achou recriações do PVPC em NTSL (ProfitChart), que confirmaram os níveis 21,4%/78,6%.

## Os dados

A série usada foram os valores **exibidos** pelos indicadores oficiais no TradingView (a linha
"Suporte n" do MIMASAR é a própria MIMA n). O ativo foi o WIN1!, em gráfico de 1 minuto, com 5.627
candles de 14 a 25/09/2026. O código dos scripts não foi acessado.

## Passo 1: quando cada MIMA nasce

O primeiro candle com valor de cada MIMA caiu exatamente em `floor(n × 4,236) − 1`:

| MIMA | 1ª barra | floor(n × 4,236) |
|---|---|---|
| 17 | 71 | 72 |
| 34 | 143 | 144 |
| 72 | 303 | 304 |
| 144 | 608 | 609 |
| 305 | 1290 | 1291 |
| 610 | 2582 | 2583 |

Duas conclusões:

- A MIMA depende de uma janela `L = floor(n × 4,236)`.
- **Não é TEMA.** Uma TEMA(L) encadeia três EMAs e só teria valor por volta de 3L barras.

Com Φ³ exato (4,2360679...), `L` da MIMA 305 seria 1292 e o da 610 seria 2584. Os dados dizem 1291 e
2583: o autor usou a constante **arredondada** 4,236.

## Passo 2: é um filtro linear?

Ajuste por mínimos quadrados de um modelo ARX(2,2) no fechamento:

```
MIMA[t] = a1·MIMA[t−1] + a2·MIMA[t−2] + b0·C[t] + b1·C[t−1]
```

Erro residual **zero** (precisão de máquina) nas 6 MIMAs. Então a MIMA é um filtro linear de 2ª ordem,
ou seja, a combinação de duas médias exponenciais.

## Passo 3: os polos viram EMAs

As raízes do polinômio `1 − a1·z − a2·z²` deram dois fatores de suavização. Cada um corresponde a uma
EMA com `alpha = 2/(P+1)`:

- um polo com P = L (a EMA lenta);
- um polo com P = E ≈ 2n (a EMA rápida).

Os pesos que reconstroem a série são **+2** na rápida e **−1** na lenta:

```
MIMA(n) = 2·EMA(E) − EMA(L)
```

É a mesma estrutura da "DEMA", mas com dois períodos diferentes, o que dá um filtro rápido e suave.

## Passo 4: a regra de E

Os 6 valores de E (35, 71, 151, 303, 643, 1287) seguem, sem exceção:

```
E = round(2n × (1 + Φ⁻⁶)) − 1        (Φ⁶ ≈ 17,944)
```

Isso vale para os 6 pontos. Fora da tabela (MIMA 1292, 2584) é extrapolação. Na MIMA 4, descoberta
depois pelo MIMASAR, a regra falha: o oficial usa E = 8, não 7.

## Passo 5: semente da EMA

Com semente = primeiro fechamento, as primeiras centenas de barras erravam dezenas de pontos. Com
semente = **média simples dos P primeiros** (o `ta.ema` do TradingView), o erro caiu para
**5,8·10⁻¹¹** desde o primeiro valor, nas 6 MIMAs.

Também foram testadas outras fontes (hl2, hlc3): o ajuste exato só acontece com o **fechamento**.

## MIMAROC

Com a MIMA exata em mãos, o "PhiCube MIMAROC Suite" oficial foi resolvido em poucas hipóteses:

```
ROC(n) = MIMA(n) − EMA(MIMA(n), 4)
```

A EMA(4) segue o padrão TV sobre a série da MIMA (semente = média das 4 primeiras MIMAs). O ROC nasce
3 barras depois da MIMA. Erro de 10⁻¹⁴ a 3·10⁻¹¹ nos 6 ROCs.

Leitura oficial: todas as linhas acima de zero = alta pura; todas abaixo = baixa pura; linhas dos dois
lados = consolidação.

## PVPC

A fórmula que já circulava em NTSL foi conferida contra o "PVPC" oficial e bateu em **100%** dos
candles, nos 6 níveis:

```
PC = mín + 21,4% × (máx − mín)
PV = mín + 78,6% × (máx − mín)
máx/mín = maior máxima / menor mínima das janelas 72, 305 e 1292 (inclui a barra atual)
```

Leitura oficial: fechou acima da PV1, alvo PV2; acima de PV1 e PV2, alvo PV3; acima das 3 PV, proibido
vender. Na venda, o espelho com as PC.

## Reproduzir

`python/phicube.py` valida qualquer CSV com a coluna `close` e colunas `M17, M34, …` (MIMA) ou
`ROC17, …` (MIMAROC) exportadas do gráfico:

```bash
python python/phicube.py seu_export.csv
```
