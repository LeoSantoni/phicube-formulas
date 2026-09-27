# MIMASAR: engenharia reversa

Feito pelo Claude (Anthropic) no Claude Code, em 26/09/2026. Fonte: os valores e as cores exibidos
pelo "PhiCube MIMASAR" oficial (TradingView), WIN1! M1, 5.627 barras. O código do script não foi
acessado. "SAR" = Suporte e Resistência.

## Estrutura do indicador oficial (28 linhas)

- **12 linhas S/R:** "Suporte n" e "Resistência n" para n = 17, 34, 72, 144, 305 e 610. O valor é
  **exatamente a MIMA n** do fechamento. Suporte e resistência da mesma MIMA nunca aparecem juntos.
- **16 linhas de alvo:** Resistência 17→Suporte 72, 34→144, 72→305, 144→610, as voltas e os
  espelhos. O valor é o da MIMA de origem.
- Cada linha tem uma paleta de 2 cores (cor própria / transparente). A pergunta era: **quando** a
  linha fica visível?

## Regra exata das 12 linhas S/R: 0 erros

Para cada MIMA n, com os dois fractais menores `a = n/4,236²` e `b = n/4,236`:

```
SUPORTE n      = (MIMA a > MIMA b > MIMA n)  E  máxima  >  MIMA n     → leque de alta + toque
RESISTÊNCIA n  = (MIMA a < MIMA b < MIMA n)  E  mínima  <= MIMA n     → leque de baixa + toque
```

| Linha | Leque |
|---|---|
| 17 | MIMA 4, 8, 17 |
| 34 | MIMA 8, 17, 34 |
| 72 | MIMA 17, 34, 72 |
| 144 | MIMA 34, 72, 144 |
| 305 | MIMA 72, 144, 305 |
| 610 | MIMA 144, 305, 610 |

Validação: 0 barras erradas em todas as 12 linhas (de 3.045 a 5.556 barras por linha, conforme o
aquecimento de cada MIMA).

A assimetria `>` na máxima e `<=` na mínima é intencional: é o que o oficial faz.

## As MIMAs "invisíveis"

As linhas 17 e 34 exigem MIMAs menores que nenhum indicador mostra. Os dados confirmaram:

- **MIMA 8 = 2·EMA(16) − EMA(33)**, que segue a fórmula padrão.
- **MIMA 4 = 2·EMA(8) − EMA(16)**. É exceção: a regra de E daria 7, mas o oficial usa 8.

## Caminho até a regra

1. Primeiro achado: o lado (suporte ou resistência) coincidia com a ordem das MIMAs, mas sobravam
   barras em que a linha deveria aparecer e não aparecia.
2. Testar "leque de 3 fractais PhiCube" (as três MIMAs em ordem numérica) reduziu os erros a um
   punhado de barras.
3. O que faltava era o **toque**: a linha só aparece quando o preço encosta no lado certo da MIMA
   (máxima acima no suporte, mínima abaixo ou igual na resistência). Com isso, zero erros.

## Linhas de alvo: ainda sem regra

- As 16 linhas vêm em **pares com visibilidade idêntica**: "Resistência a → Suporte b" acende
  exatamente nas mesmas barras que "Suporte b → Resistência a". É um estado ("preço entre a MIMA a e
  a MIMA b") desenhado nas duas pontas.
- **Não** é "S/R de a ativo E S/R de b ativo" (123 a 400 erros por linha).
- A melhor aproximação ("leque de baixa de a, preço abaixo da MIMA a e acima da MIMA b") ainda erra
  de 58 a 128 barras por linha. Provavelmente o indicador guarda estado/memória.
