# vIBC Core Smart Contracts

This project includes

- vIBC Core Smart Contracts (CoreSC)
- a few demo contracts that simulate dev users protocol contracts, eg. Mars, etc.

## Quick Start with Forge/Foundry

### Install Forge

```sh
curl -L https://foundry.paradigm.xyz | bash
```

This will install Foundryup, then simply follow the instructions on-screen, which will make the `foundryup` command available in your CLI.

Running `foundryup` by itself will install the latest (nightly) precompiled binaries: `forge`, `cast`, `anvil`, and `chisel`. See `foundryup --help` for more options, like installing from a specific version or commit.

Or go to https://book.getfoundry.sh/getting-started/installation for more installation options.

### Build contracts

```sh
forge build
```

### Run Tests

```sh
forge test
```

### Clean environment

```sh
forge clean
```
