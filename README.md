# Wallet App Store

Third (or 4th) winning project at the first StarkNet Hackathon (Amsterdam, 2022).

The goal of this project is to create an "Account App Store". The motivation is the following: a typical web2 user can invest a limited amount of time and attention into selecting the apps that best fit their needs. Nevertheless, there are tens of thousands of different apps available. The way this is solved is, partially, is through the so-called "app-stores", where apps are rated by users and are organized by different categories.

We believe a similar marketplace will be needed for web3.
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
### Install Protostar
```
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```
### Add dependencies
```
protostar install https://github.com/OpenZeppelin/cairo-contracts
```
### Compile contracts
```
protostar build --cairo-path ./lib/cairo_contracts/src
```
### Testing
```
protostar test ./tests --cairo-path ./lib/cairo_contracts/src
```