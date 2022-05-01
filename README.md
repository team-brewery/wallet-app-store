# Wallet App Store


## Description

Third (or 4th) winning project at the first **StarkNet Hackathon** (Amsterdam, 2022).

The goal of this project is to create an "Account App Store".

The motivation is the following: a typical web2 user can invest a limited amount of time and attention into selecting the apps that best fit their needs. Nevertheless, there are tens of thousands of different apps available. The way this is solved is, partially, through the so-called **"app-stores"**, where apps are rated by users and are organized by different categories. Moreover, the app-store generates data which can be analysed in order to provide recomentations to the user, etc.

We believe a **similar marketplace** will be needed for web3. In this project we created the first prototype of what a marketplace for account contracts in StarkNet could be. The idea is that when one creates an account through their wallet (Argent X, Braavoc, etc.), the user can select what type of account they want to deploy. Some examples of accounts we thought (and partially/fully implemented) of are:

- Allowlist-Denylist Account (described below)
- Multisignature Account
- Custom Cryptographic Digital Signature Account
- Fee Insured Account
- Mixes of the above
- Etc.

[Here](https://pitch.com/public/3454e0c7-ec9d-4111-82c3-4486de25e252/bc44edd0-287d-4b90-8898-ceb42d12e185) are the slides of our project presentation.



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
