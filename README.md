# Wrapped SLP

The project enables minting and burning wrapped SLP on the Ethereum blockchain.
Wrapped token contract for the original SLPs can be created by any user via `Factory`. The supply of the wrapped assets is managed by the `Multisig` in accordance with the principle as many tokens are locked on the BCH multisig as many wrapped SLP tokens can exist.

The Wrapped SLP can burned and converted to the original SLP. The request can be canceled prior the original SLP are sent to the address.

The fee of ~1% per year is charged from the Wrapped SLP holders and then burned causing the inflation and thus rewarding the original SLP holders.

The system consist of the three contract:

- `WrappedSLP` : ERC20 token represented the SLP asset
- `Factory` : contract for deploying new Wrapped assets and searching for the existing ones.
- `MultisigWallet` : Gnosis multisig upgraded to the solidity v7.

## Usage

Install dependencies:

```
yarn
```

Compile:

```
yarn compile
```

Deploy contracts:

```
yarn migrate
```

Verify contracts on Etherscan:

```
yarn verify --network YOUR_NETWORK
```

Test:

```
yarn test
```

Read `test.md` to learn more about test coverage.
