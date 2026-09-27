"""PhiCube - implementacao de referencia das formulas abertas + validador.

MIMA(n)    = 2*EMA(close, E) - EMA(close, L)
             L = floor(n*4.236) ; E = round(2n*(1+phi^-6)) - 1  (excecao: MIMA 4 usa E = 8)
MIMAROC(n) = MIMA(n) - EMA(MIMA(n), 4)
PVPC       = PC = min + 21,4% (max-min) ; PV = min + 78,6% (max-min) ; janelas 72/305/1292
MIMASAR(n) = suporte  se MIMA a > MIMA b > MIMA n e maxima  >  MIMA n
             resist.  se MIMA a < MIMA b < MIMA n e minima <= MIMA n
             (a, b = os dois fractais PhiCube menores que n)

EMA no padrao TradingView (ta.ema): alpha 2/(P+1), semente = media simples dos
P primeiros valores, na barra P-1.

Uso:
    from phicube import mima, mimaroc, pvpc, mimasar
    serie = mima(close_array, 144)

    python phicube.py dados.csv   # valida contra colunas close e M17, M34..., ROC17...
"""
import math
import sys

import numpy as np

PHI = (1 + 5 ** 0.5) / 2

# leque de 3 fractais usado pelo MIMASAR de cada MIMA
LEQUE_SAR = {17: (4, 8), 34: (8, 17), 72: (17, 34), 144: (34, 72), 305: (72, 144), 610: (144, 305)}


def periodos(n: int) -> tuple[int, int]:
    """(L lenta, E rapida) da MIMA n. Exatos para 4/8/17/34/72/144/305/610."""
    lenta = math.floor(n * 4.236)                       # Phi^3 ARREDONDADO!
    rapida = round(2 * n * (1 + PHI ** -6)) - 1
    if n == 4:
        rapida = 8                                      # excecao confirmada no MIMASAR
    return lenta, rapida


def ema_tv(x: np.ndarray, p: int) -> np.ndarray:
    """EMA identica ao ta.ema do TradingView (NaN antes da barra p-1)."""
    out = np.full(len(x), np.nan)
    if len(x) < p:
        return out
    out[p - 1] = x[:p].mean()
    a = 2.0 / (p + 1)
    for i in range(p, len(x)):
        out[i] = out[i - 1] + a * (x[i] - out[i - 1])
    return out


def mima(close, n: int) -> np.ndarray:
    """Serie da MIMA n (NaN ate a barra L-1)."""
    c = np.asarray(close, dtype=float)
    lenta, rapida = periodos(n)
    return 2 * ema_tv(c, rapida) - ema_tv(c, lenta)


def mimaroc(close, n: int) -> np.ndarray:
    """ROC oficial: MIMA(n) - EMA(MIMA(n), 4) (EMA padrao TradingView)."""
    m = mima(close, n)
    out = np.full(len(m), np.nan)
    if not np.isfinite(m).any():
        return out
    i0 = int(np.isfinite(m).argmax())
    out[i0:] = m[i0:] - ema_tv(m[i0:], 4)
    return out


def pvpc(high, low, janela: int) -> tuple[np.ndarray, np.ndarray]:
    """(PC, PV) da janela (72, 305 ou 1292). A janela inclui a barra atual."""
    h = np.asarray(high, dtype=float)
    lo = np.asarray(low, dtype=float)
    pc = np.full(len(h), np.nan)
    pv = np.full(len(h), np.nan)
    for i in range(janela - 1, len(h)):
        mx = h[i - janela + 1:i + 1].max()
        mn = lo[i - janela + 1:i + 1].min()
        pc[i] = mn + 0.214 * (mx - mn)
        pv[i] = mn + 0.786 * (mx - mn)
    return pc, pv


def mimasar(high, low, close, n: int) -> np.ndarray:
    """Estado do MIMASAR da MIMA n: +1 suporte, -1 resistencia, 0 oculto.
    O valor da linha, quando visivel, e a propria mima(close, n)."""
    a, b = LEQUE_SAR[n]
    ma, mb, mn = mima(close, a), mima(close, b), mima(close, n)
    h = np.asarray(high, dtype=float)
    lo = np.asarray(low, dtype=float)
    ok = np.isfinite(ma) & np.isfinite(mb) & np.isfinite(mn)
    sup = ok & (ma > mb) & (mb > mn) & (h > mn)
    res = ok & (ma < mb) & (mb < mn) & (lo <= mn)
    return sup.astype(int) - res.astype(int)


def _validar(csv_path: str) -> None:
    import pandas as pd
    d = pd.read_csv(csv_path)
    c = d["close"].to_numpy(float)
    for col in [k for k in d.columns if k.startswith("ROC") and k[3:].isdigit()]:
        n = int(col[3:])
        y = d[col].to_numpy(float)
        z = mimaroc(c, n)
        m = np.isfinite(y) & np.isfinite(z)
        print(f"{col}: erro_max={np.abs(z[m] - y[m]).max():.2e} candles={m.sum()}")
    for col in [k for k in d.columns if k.startswith("M") and k[1:].isdigit()]:
        n = int(col[1:])
        y = d[col].to_numpy(float)
        z = mima(c, n)
        m = np.isfinite(y) & np.isfinite(z)
        if not m.any():
            print(f"{col}: sem sobreposicao")
            continue
        lenta, rapida = periodos(n)
        print(f"{col}: L={lenta} E={rapida} erro_max={np.abs(z[m] - y[m]).max():.2e} "
              f"candles={m.sum()}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    _validar(sys.argv[1])
