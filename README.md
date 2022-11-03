# Super Liquidator

Feature parity batch liquidator in huff that:

- caches calldata to be reused for each liquidation
- copies array elements directly from calldata to liquidation args
- removes selector checks
- removes ether checks
- removes type checks
- removes length checks

## Possible optimizations:

- cache the host address to avoid unnecessary calldataload calls
- cache zeros and word sizes for dup calls
- bit shift selectors to reduce contract size
- improve balance call by loading and decoding agreement state slots from the
    token directly

## Gas Diffs

```py
single_liq      = 241_985
multi_liq       = 469_256
old_single_liq  = 326_164
old_multi_liq   = 556_798

per_call        = 227_271
old_per_call    = 230_634
```
