# Template for Polymer Challenge 3

This repo provides template code to complete Polymer Testnet Challenge 3: https://forum.polymerlabs.org/t/challenge-3-cross-contract-query-with-polymer/475

## 📚 Documentation

There's some basic information here in the README but a more comprehensive documentation can be found in [the official Polymer documentation](https://docs.polymerlabs.org/docs/category/build-ibc-dapps-1).

## 📋 Prerequisites

The repo is **compatible with both Hardhat and Foundry** development environments.

- Have [git](https://git-scm.com/downloads) installed
- Have [node](https://nodejs.org) installed (v18+)
- Have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (Hardhat will be installed when running `npm install`)
- Have [just](https://just.systems/man/en/chapter_1.html) installed (recommended but not strictly necessary)

You'll need some API keys from third party's:
- [Optimism Sepolia](https://optimism-sepolia.blockscout.com/account/api-key) and [Base Sepolia](https://base-sepolia.blockscout.com/account/api-key) Blockscout Explorer API keys
- Have an [Alchemy API key](https://docs.alchemy.com/docs/alchemy-quickstart-guide) for OP and Base Sepolia

Some basic knowledge of all of these tools is also required, although the details are abstracted away for basic usage.

## 🧰 Install dependencies

To compile your contracts and start testing, make sure that you have all dependencies installed.

From the root directory run:

```bash
just install
```

to install the [vIBC core smart contracts](https://github.com/open-ibc/vibc-core-smart-contracts) as a dependency.

Additionally Hardhat will be installed as a dev dependency with some useful plugins. Check `package.json` for an exhaustive list.

> Note: In case you're experiencing issues with dependencies using the `just install` recipe, check that all prerequisites are correctly installed. If issues persist with forge, try to do the individual dependency installations...

## ⚙️ Set up your environment variables

Convert the `.env.example` file into an `.env` file. This will ignore the file for future git commits as well as expose the environment variables. Add your private keys and update the other values if you want to customize (advanced usage feature).

```bash
cp .env.example .env
```

This will enable you to sign transactions with your private key(s). If not added, the scripts from the justfile will fail.

### Configuration file

The configuration file is where all important data is stored for the just commands and automation. We strive to make direct interaction with the config file as little as possible.

By default the configuration file is stored at root as `config.json`.

**The configuration file is pre-set with the contract you will need to interact with on Base. Do not change it in order to correctly complete the challenge**

### Obtaining testnet ETH

The account associated with your private key must have both Base Sepolia and Optimism Sepolia ETH. To obtain the testnet ETH visit:

- [Optimism Sepolia Faucet](https://www.alchemy.com/faucets/optimism-sepolia)
- [Base Sepolia Faucet](https://www.alchemy.com/faucets/base-sepolia)

## 🏃🏽🏃🏻‍♀️ Instructions

The project comes with an almost complete contract `CCQueryUC.sol` in the contracts directory. Your task is to implement two functions:

1. `sendUniversalPacket` - You will need to configure the payload to correctly be decoded and pass conditional logic of the base contract you are sending the packet to. 
2. `onUniversalAcknowledgement` - You will need to emit the event `LogAcknowledgment` in order to provide evidence to complete this challenge. 

Once you have completed the implementation of these two functions, run:

`just run-challenge-3`

This will:
1. Deploy your CCQueryUC.sol contract to Optimism
2. Send a packet to the Base Contract


## 💡 Questions or Suggestions?

Feel free to open an issue for questions, suggestions, or discussions related to this repository. For further discussion as well as a showcase of some community projects, check out the [Polymer developer forum](https://forum.polymerlabs.org).

Thank you for being a part of our community!
