# Wallet App Store
## Description

### White and Blacklist Account
This account contract has a whitelist and blacklist mechanism with varying levels of degeneracy. Depending on
your risk appetite

LEVEL 0: SAFE
    - Funds are SAFU
    - Can only interact with contracts that are whitelisted and cannot interact with blacklisted (even if mistakenly whitelisted)

LEVEL 1: DEGEN
    - You like to spice things up a bit and have some risks
    - Cannot interact with contracts that are blacklisted but there is no whitelist

LEVEL 2: FULL DEGEN
    - YOLO
    - You like pain and throwing away money

## Commands

```
protostar build --cairo-path ./lib/cairo_contracts/src
```

```
protostar test ./tests --cairo-path ./lib/cairo_contracts/src
```