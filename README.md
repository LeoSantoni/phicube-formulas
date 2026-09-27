# Fórmulas PhiCube: MIMA, MIMAROC, PVPC e MIMASAR

As fórmulas dos principais indicadores da metodologia PhiCube foram **descobertas pelo Claude (IA da
Anthropic) por engenharia reversa**. O trabalho foi feito em setembro de 2026, no Claude Code.

A MIMA e seus derivados são proprietários: nem a PhiCube nem a Nelogica publicam as fórmulas. Os
fóruns só tinham chutes (EMA, TEMA, Alligator...). O Claude partiu dos **valores exibidos** pelos
indicadores oficiais no TradingView, candle a candle, e chegou às fórmulas **exatas**. Elas reproduzem
o oficial com erro de 10⁻¹¹ ponto, ou seja, só arredondamento de ponto flutuante.

> O código dos scripts oficiais **nunca foi acessado**. Tudo foi deduzido dos números que o gráfico
> mostra, como quem mede uma caixa-preta por fora.

## Resultado

| Indicador | Fórmula | Erro vs. oficial |
|---|---|---|
| **MIMA** | `2·EMA(close, E) − EMA(close, L)` | 5,8·10⁻¹¹ |
| **MIMAROC** | `MIMA(n) − EMA(MIMA(n), 4)` | 10⁻¹⁴ a 3·10⁻¹¹ |
| **PVPC** | `PC = mín + 21,4%·range` ; `PV = mín + 78,6%·range` (janelas 72/305/1292) | 0 |
| **MIMASAR** | leque de 3 MIMAs + toque do preço na MIMA | 0 barras erradas |

Base da validação: WIN1! (mini-índice B3), gráfico de 1 minuto, 5.627 candles (14 a 25/09/2026).

### MIMA

```
MIMA(n) = 2 × EMA(Fechamento, E) − EMA(Fechamento, L)

L = floor(n × 4,236)                 ← Φ³ ARREDONDADO para 4,236
E = round(2n × (1 + Φ⁻⁶)) − 1        ← Φ = 1,6180339887
```

EMA no padrão TradingView (`ta.ema`): `alpha = 2/(P+1)`. O primeiro valor é a **média simples** dos P
primeiros fechamentos; depois o cálculo é recursivo. A MIMA nasce na barra `L−1`.

| MIMA | L (lenta) | E (rápida) |
|---|---|---|
| 4 ¹ | 16 | 8 |
| 8 ¹ | 33 | 16 |
| 17 | 72 | 35 |
| 34 | 144 | 71 |
| 72 | 304 | 151 |
| 144 | 609 | 303 |
| 305 | 1291 | 643 |
| 610 | 2583 | 1287 |

¹ MIMAs "invisíveis": não aparecem no gráfico, mas o MIMASAR usa. A MIMA 4 é exceção à regra de E
(usa E = 8, não 7).

### MIMAROC

```
ROC(n) = MIMA(n) − EMA(MIMA(n), 4)
```

A EMA(4) segue o mesmo padrão TradingView, aplicada sobre a série da MIMA. O ROC nasce 3 barras
depois da MIMA.

### PVPC (linhas verdes e vermelhas)

```
PC = mín + 0,214 × (máx − mín)        (vermelhas: PC1, PC2, PC3)
PV = mín + 0,786 × (máx − mín)        (verdes:    PV1, PV2, PV3)
```

`máx`/`mín` = maior máxima e menor mínima das últimas **72 / 305 / 1292** barras, contando a atual.

### MIMASAR (suporte e resistência das MIMAs)

Para cada MIMA n, com `a` e `b` = os dois fractais PhiCube menores:

```
SUPORTE n      = MIMA a > MIMA b > MIMA n   E   máxima  >  MIMA n
RESISTÊNCIA n  = MIMA a < MIMA b < MIMA n   E   mínima  <= MIMA n
```

| Linha | Leque (a, b, n) |
|---|---|
| 17 | 4, 8, 17 |
| 34 | 8, 17, 34 |
| 72 | 17, 34, 72 |
| 144 | 34, 72, 144 |
| 305 | 72, 144, 305 |
| 610 | 144, 305, 610 |

O valor da linha, quando aparece, é a própria MIMA n.

## Como o Claude chegou lá

O passo a passo completo está em [docs/descoberta.md](docs/descoberta.md) e
[docs/mimasar.md](docs/mimasar.md). Em resumo:

1. **O primeiro candle entrega a janela.** Cada MIMA só começa a existir depois de um número fixo
   de barras: `floor(n × 4,236)`. Isso já descartou a hipótese do fórum (TEMA), que levaria cerca de
   3× mais barras para nascer.
2. **Ajuste de filtro linear.** Um modelo recursivo de 2ª ordem sobre o fechamento
   (`MIMA[t] = a1·MIMA[t−1] + a2·MIMA[t−2] + b0·C[t] + b1·C[t−1]`) encaixou com erro **zero**.
   Então a MIMA é uma combinação de duas médias exponenciais.
3. **Os polos do filtro revelaram as duas EMAs**, EMA(L) e EMA(E), com pesos **+2 e −1**.
4. **O detalhe que ninguém acertaria no chute:** a constante é Φ³ **arredondado** para 4,236. Com o
   valor exato (4,23607...), as MIMAs 305 e 610 deixam de bater.
5. **Derivados.** Com a MIMA exata, o MIMAROC e a regra de exibição do MIMASAR saíram testando
   hipóteses contra os valores e as cores de cada linha oficial, até zerar os erros.

## Conteúdo do repositório

| Pasta | O quê |
|---|---|
| [`python/phicube.py`](python/phicube.py) | Implementação de referência (`mima`, `mimaroc`, `pvpc`, `mimasar`) + validador contra CSV |
| [`mql5/`](mql5/) | Indicadores MetaTrader 5: `PHICUBE_PVPC_MIMA`, `PHICUBE_MIMASAR`, `PHICUBE_MIMAROC` |
| [`pine/`](pine/) | Indicador TradingView (Pine v5) com MIMAs + PVPC + MIMASAR |
| [`skills/phicube-mima/`](skills/phicube-mima/) | **Skill do Claude**: ensina o Claude a usar as fórmulas certas ao criar indicadores e robôs |
| [`docs/`](docs/) | Histórico da descoberta e da engenharia reversa |

### Usar a skill no Claude Code

Copie a pasta `skills/phicube-mima` para `~/.claude/skills/`. Depois é só pedir, por exemplo:
*"cria um indicador MQL5 com a MIMA 72 e as linhas PVPC"*. O Claude vai usar as fórmulas exatas em vez
de aproximar por EMA.

```bash
git clone https://github.com/LeoSantoni/phicube-formulas.git
cp -r phicube-formulas/skills/phicube-mima ~/.claude/skills/
```

### Aquecimento (importante)

A EMA lenta precisa de cerca de **5 × L barras** para "esquecer" o valor inicial. A MIMA 610, por
exemplo, precisa de ~13.000 barras. Antes disso o valor ainda não é igual ao oficial. No MT5, aumente
"Máx. barras no gráfico"; no Strategy Tester, comece o teste cerca de um mês antes.

## O que ainda falta

- As **16 linhas de alvo** do MIMASAR oficial (R17→S72 etc.) não têm regra exata; tudo indica que
  guardam estado/memória.
- A **MIMA 2** não foi identificada: nenhum script oficial disponível a exibe.
- A regra de `E` foi deduzida de 6 pontos exatos. Para MIMAs fora da tabela (1292, 2584) o valor é
  extrapolação.

## Avisos

- Projeto independente, **sem relação com a PhiCube, a Nelogica ou o TradingView**. Os nomes dos
  indicadores pertencem aos seus donos. Os indicadores oficiais continuam sendo a referência.
- Não inclui código, dados exportados nem material de curso dos produtos oficiais. Só as fórmulas
  deduzidas e implementações próprias.
- Não é recomendação de investimento. Operar no mercado envolve risco de perda.

## Licença

[MIT](LICENSE).
