# Sagon Protocol

![Stars](https://img.shields.io/github/stars/bourdillion/sagon)
![Contributors](https://img.shields.io/github/contributors/bourdillion/sagon?color=brightgreen)
![Issues](https://img.shields.io/github/issues/bourdillion/sagon)
![License](https://img.shields.io/github/license/bourdillion/sagon)

## About Sagon 
Sagon brings a cheap, easy and efficient way of batch-sending a token to multiple addresses at a go. It is a single-page application where users can come, enter in the addresses of the account to send money to and the equivalent amount, and simply hit send. The core of the protocol is written in pure huff language designed to make it much more cheaper to send transactions. Users also have the option of paying for gas fees in another accepted token instead of eth.

## Resources

* [Website](https://sagon.tech) - Visit the website to experience Sagon as a user.
* [Documentation](https:/sagon.tech) - Read the Sagon docs for a more indepth explanation.
* [Audits](https:/sagon.tech) - Read a mini audit report here.




## Overview
This repository holds the smart contract logic for the pilot version of the Sagon protocol. The logic of the contract is written in huff, Assembly(yul) and solidity for reference. Users have the option to switch between using the contract written in huff, yul and solidity. The repository contains logic to batch send tokens, and also to check if the list of addresses with their amounts are correct.

## Dependencies

The smart contracts in this repository import code from:
1. [Forge-std](https://github.com/foundry-rs/forge-std)
2. [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
3. [Foundry-huff](https://github.com/huff-language/foundry-huff.git)

To check version of the dependencies, use `git submodule status`.

## Setup

#### Make sure to have foundry installed
``` javascript
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
```

#### Verify installation:
` forge --version`

#### Clone the Repository
```
    git clone https://github.com/bourdillion/sagon.git
    cd sagon
```

#### Install Dependencies
`forge install`

#### Build the contracts
`forge build`

#### Run all tests
`forge test`

#### Run a specific test
`forge test --mt <test_name>`

## Audit Report
Audits are currently in progress, will be updated soon.


