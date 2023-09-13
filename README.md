# Vinu SFC

## Supported operating system

The project is supported on all UNIX (and UNIX-like) OS's and not supported on Windows.

## Dependencies

Make sure you have docker (>= v20) installed.

```bash
docker -v
```

Make sure you have node (>= v16.17.0) and npm (>= v8.18.0) installed.

```bash
node -v
npm -v
```

Make sure you have yarn (>= v1.22.19) installed.

```bash
yarn -v
```

## Build

```bash
$ yarn
$ make
```

## Project Structure

This is a truffle javascript project.
Solidity version `0.5.17`. For the contracts to work correctly, the experimental pragma ABIEncoderV2 was used.

### Tests

Tests are found in the `./test/` folder.

To run tests

```bash
$ yarn ganache-cli --gasLimit 50000000 --gasPrice 0 --allowUnlimitedContractSize --defaultBalanceEther 5000000000
$ yarn test
```

To run coverage

```bash
$ yarn truffle run coverage
```

It is recommended to close all other applications while running tests, otherwise tests may fail due to time out.

### Contracts

Solidity smart contracts are found in `./contracts/`.
`./contracts/test` folder contains mock contracts that are used for testing purposes.

## Test Coverage

```text
  Contract: SFC
    Nde
      ✓ Should migrate to New address (67ms)
      ✓ Should not migrate if not owner (493ms)
      ✓ Should not copyCode if not owner (59ms)
      ✓ Should copyCode (44ms)
      ✓ Should update network version (68ms)
      ✓ Should not update network version if not owner (55ms)
      ✓ Should advance epoch (64ms)
      ✓ Should not set a new storage if not backend address (73ms)
      ✓ Should not advance epoch if not owner (103ms)
      ✓ Should not set backend if not backend address (91ms)
      ✓ Should not swap code if not backend address (93ms)
      ✓ Should not be possible add a Genesis Validator through NodeDriver if not called by Node (148ms)
      ✓ Should not be possible to deactivate a validator through NodeDriver if not called by Node (233ms)
      ✓ Should not be possible to add a Genesis Delegation through NodeDriver if not called by node (100ms)
      ✓ Should not be possible to seal Epoch Validators through NodeDriver if not called by node (76ms)
      ✓ Should not be possible to seal Epoch through NodeDriver if not called by node (133ms)
    Genesis Validator
      ✓ Set Genesis Validator with bad Status (78ms)
      ✓ should reject sealEpoch if not called by Node (63ms)
      ✓ should reject SealEpochValidators if not called by Node (63ms)

  Contract: SFC
    Basic functions
      Constants
        ✓ Returns current Epoch
        ✓ Returns minimum amount to stake for a Validator
        ✓ Returns the maximum ratio of delegations a validator can have
        ✓ Returns the ratio of the reward rate at base rate (without lockup)
        ✓ Returns the minimum duration of a stake/delegation lockup
        ✓ Returns the maximum duration of a stake/delegation lockup (41ms)
        ✓ Returns the period of time that stake is locked (39ms)
        ✓ Returns the number of epochs that stake is locked (64ms)
        ✓ Returns the version of the current implementation (325ms)
        ✓ Should create a Validator and return the ID (568ms)
        ✓ Should fail to create a Validator insufficient self-stake (77ms)
        ✓ Should fail if pubkey is empty (70ms)
        ✓ Should create two Validators and return the correct last validator ID (822ms)
        ✓ Should return Delegation (551ms)
        ✓ Should reject if amount is insufficient for self-stake (95ms)
        ✓ Returns current Epoch
        ✓ Should return current Sealed Epoch (224ms)
        ✓ Should return Now()
        ✓ Should return getTime() (44ms)
      Initialize
        ✓ Should have been initialized with firstValidator
      Ownable
        ✓ Should return the owner of the contract (153ms)
        ✓ Should return true if the caller is the owner of the contract (92ms)
        ✓ Should return address(0) if owner leaves the contract without owner (86ms)
        ✓ Should transfer ownership to the new owner (145ms)
        ✓ Should not be able to transfer ownership if not owner (93ms)
        ✓ Should not be able to transfer ownership to address(0) (112ms)
      Events emitters
        ✓ Should call updateNetworkRules (68ms)
        ✓ Should call updateOfflinePenaltyThreshold (73ms)

  Contract: SFC
    Prevent Genesis Call if not node
      ✓ Should not be possible add a Genesis Validator if called not by node (63ms)
      ✓ Should not be possible add a Genesis Delegation if called not by node (54ms)
    Create validators
      ✓ Should create Validators (845ms)
      ✓ Should return the right ValidatorID by calling getValidatorID (1016ms)
      ✓ Should not be able to stake if Validator not created yet (1155ms)
      ✓ Should stake with different delegators (2030ms)
      ✓ Should return the amount of delegated for each Delegator (2865ms)
      ✓ Should return the total of received Stake (1209ms)

  Contract: SFC
    Returns Validator
      ✓ Should returns Validator' status 
      ✓ Should returns Validator' Deactivated Time
      ✓ Should returns Validator' Deactivated Epoch
      ✓ Should returns Validator's Received Stake
      ✓ Should returns Validator's Created Epoch
      ✓ Should returns Validator's Created Time
      ✓ Should returns Validator's Auth (address)
    EpochSnapshot
      ✓ Returns stashedRewardsUntilEpoch (987ms)
    Methods tests
      ✓ checking createValidator function (1571ms)
      ✓ checking sealing epoch (1816ms)

  Contract: SFC
    Staking / Sealed Epoch functions
      ✓ Should return claimed Rewards until Epoch (2111ms)
      ✓ Check pending Rewards of delegators (1937ms)
      ✓ Check if pending Rewards have been increased after sealing Epoch (2805ms)
      ✓ Should increase balances after claiming Rewards (2452ms)
      ✓ Should increase stake after restaking Rewards (2196ms)
      ✓ Should increase locked stake after restaking Rewards (2152ms)
      ✓ Should return stashed Rewards (2160ms)
      ✓ Should update the validator on node (282ms)
      ✓ Should not be able to deactivate validator if not Node (136ms)
      ✓ Should seal Epochs (409ms)
      ✓ Should seal Epoch on Validators (375ms)
    Stake lockup
      ✓ Check pending Rewards of delegators (1291ms)
      ✓ Check if pending Rewards have been increased after sealing Epoch (1742ms)
      ✓ Should increase balances after claiming Rewards (1617ms)
      ✓ Should return stashed Rewards (1355ms)
      ✓ Should return pending rewards after unlocking and re-locking (9584ms)
    NodeDriver
      ✓ Should not be able to call `setGenesisValidator` if not NodeDriver (93ms)
      ✓ Should not be able to call `setGenesisDelegation` if not NodeDriver (86ms)
      ✓ Should not be able to call `deactivateValidator` if not NodeDriver (81ms)
      ✓ Should not be able to call `deactivateValidator` with wrong status (59ms)
      ✓ Should deactivate Validator (95ms)
      ✓ Should not be able to call `sealEpochValidators` if not NodeDriver (111ms)
      ✓ Should not be able to call `sealEpoch` if not NodeDriver (214ms)
    Epoch getters
      ✓ should return EpochvalidatorIds (105ms)
      ✓ should return the Epoch Received Stake (86ms)
      ✓ should return the Epoch Accumulated Reward Per Token (91ms)
      ✓ should return the Epoch Accumulated Uptime (83ms)
      ✓ should return the Epoch Accumulated Originated Txs Fee (135ms)
      ✓ should return the Epoch Offline time  (74ms)
      ✓ should return Epoch Offline Blocks (122ms)
    Unlock features
      ✓ should fail if trying to unlock stake if not lockedup (87ms)
      ✓ should fail if trying to unlock stake if amount is 0 (85ms)
false
      ✓ should return if slashed (61ms)
      ✓ should fail if delegating to an unexisting validator (109ms)
      ✓ should fail if delegating to an unexisting validator (2) (141ms)
    SFC Rewards getters / Features
BN { negative: 0, words: [ 0, <1 empty item> ], length: 1, red: null }
      ✓ should return stashed rewards
BN { negative: 0, words: [ 0, <1 empty item> ], length: 1, red: null }
      ✓ should return locked stake (58ms)
BN { negative: 0, words: [ 0, <1 empty item> ], length: 1, red: null }
      ✓ should return locked stake (2)

  Contract: SFC
    Staking / Sealed Epoch functions
      ✓ Should setGenesisDelegation Validator (141ms)

  Contract: SFC
    Test Rewards Calculation
      ✓ Calculation of validators rewards should be equal to 30% (1089ms)
      ✓ Should not be able withdraw if request does not exist (222ms)
      ✓ Get stakes/get wr requests should correctly work after undelegate (5867ms)
      ✓ Should not be able to undelegate 0 amount (763ms)
      ✓ Should not be able to undelegate if not enough unlocked stake (920ms)
      ✓ Should not be able to unlock if not enough unlocked stake (1171ms)
      ✓ should return the unlocked stake (968ms)
      ✓ Should not be able to claim Rewards if 0 rewards (2181ms)

  Contract: SFC
    Test Calculation Rewards with Lockup
      ✓ Should not be able to lock 0 amount (1087ms)
      ✓ Should not be able to lock more than a year (1710ms)
      ✓ Should not be able to lock more than validator lockup period (2107ms)
      ✓ Should not be able to lock more than validator lockup period (1318ms)
      ✓ Should be able to lock for 1 month (3671ms)
      ✓ Should not unlock if not locked up FTM (3067ms)
      ✓ Should not be able to unlock more than locked stake (2180ms)
      ✓ Unlocking penalty should be 0 for delegator (5163ms)
      ✓ Should unlock after period ended and stash rewards will be reverted (3386ms)

  Contract: SFC
    Test Rewards with lockup Calculation
      ✓ Should not update slashing refund ratio (1897ms)
      ✓ Should not sync if validator does not exist (508ms)


  123 passing (20m)

-------------------------|----------|----------|----------|----------|----------------|
File                     |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
-------------------------|----------|----------|----------|----------|----------------|
 common/                 |      100 |    83.33 |      100 |      100 |                |
  Decimal.sol            |      100 |      100 |      100 |      100 |                |
  Initializable.sol      |      100 |    83.33 |      100 |      100 |                |
 erc20/base/             |        0 |        0 |        0 |        0 |                |
  ERC20.sol              |        0 |        0 |        0 |        0 |... 220,230,231 |
  ERC20Burnable.sol      |        0 |      100 |        0 |        0 |       18,27,35 |
  ERC20Detailed.sol      |        0 |      100 |        0 |        0 |... 24,31,39,55 |
  ERC20Mintable.sol      |        0 |        0 |        0 |        0 |... 45,58,59,60 |
  IERC20.sol             |      100 |      100 |      100 |      100 |                |
  MinterRole.sol         |        0 |        0 |        0 |        0 |... 32,33,37,38 |
  Roles.sol              |        0 |        0 |        0 |        0 |... 26,27,39,40 |
 ownership/              |      100 |      100 |      100 |      100 |                |
  Ownable.sol            |      100 |      100 |      100 |      100 |                |
 sfc/                    |    79.45 |    61.22 |    78.74 |    79.06 |                |
  NetworkInitializer.sol |        0 |      100 |        0 |        0 |    31,32,34,40 |
  NodeDriver.sol         |    60.87 |       50 |    57.89 |    58.82 |... 489,500,516 |
  SFC.sol                |    85.07 |    65.52 |    94.52 |    85.01 |... 0,1661,1686 |
  StakeTokenizer.sol     |        0 |        0 |        0 |        0 |... 52,57,60,68 |
  StakersConstants.sol   |    81.82 |      100 |    81.82 |    81.82 |          83,88 |
 test/                   |      100 |      100 |       80 |      100 |                |
  SFCI.sol               |      100 |      100 |      100 |      100 |                |
  StubEvmWriter.sol      |      100 |      100 |       40 |      100 |                |
  UnitTestSFC.sol        |      100 |      100 |      100 |      100 |                |
 version/                |      100 |      100 |      100 |      100 |                |
  Version.sol            |      100 |      100 |      100 |      100 |                |
-------------------------|----------|----------|----------|----------|----------------|
All files                |    72.27 |    56.96 |    66.49 |    71.96 |                |
-------------------------|----------|----------|----------|----------|----------------|
```

## Technical Requirements

The technical requirement document describes the product's functionality and purpose.
It can be found [here](https://drive.google.com/drive/folders/1s8bOV2v7yDzQoq3FML-vuvvMvAHBWePa).

## Implementation Details

### Audit scope

The following files contain code that will be deployed in genesis block on mainnet and thus require a security audit:

- `SFC.sol`
- `NodeDriver.sol`
- `NetworkInitializer.sol`
- `StakersConstants.sol`
- `Initializable.sol`
- `Ownable.sol`
- `Version.sol`
- `Decimal.sol`

### Architecture

The system consists of several contracts that implement the underlying proof-of-stake blockchain system and system node contracts. 

The core contract is `SFC`. It maintains a group of validators and their delegations. It distributes the rewards, based on internal transaction created by the node.

The `NodeDriver` and `NodeDriverAuth` contracts are designed to manage the entire blockchain system (increase the native balance, nonce, manage contract storage slots etc.).

The `NetworkInitializer` contract is intended for initializing `SFC`, `NodeDriver` and `NodeDriverAuth` contracts in one call to allow fewer genesis transactions.

### Role Model

The `SFC` and `NodeDriverAuth` contracrs has one owner role:

- In `SFC` contract the owner can update such parameters as base validators reward per second, offline penalty threshold blocks and time, slashing refund ratio, native token total supply. Also owner can mint native token and update `StakeTokenizer` contract address.

- In `NodeDriverAuth` contract the owner can migrate `NodeDriverAuth` contract to new address, upgrade the code of some contract, increase the nonce of some address, update the network rules, update the network version and increase the number of epochs in the blockchain.

### Backend

The contracts system is deployed in the genesis block and controlled by the fantom go-opera node with its modifications.

### Notes

The getStakes function does not guarantee that the order of stakes will be maintained over time. External agents
(including other contracts) shouldn't assume the ordering to be consistent.
