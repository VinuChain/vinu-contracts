# Vinu SFC

## Supported operating system

The project is supported on all UNIX (and UNIX-like) OS's and not supported on Windows.

## Build

Make sure you have docker (>= v20) installed.

```bash
docker -v
```

If it's installed build the project.

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
$ make
$ yarn ganache-cli --gasLimit 50000000 --gasPrice 0 --allowUnlimitedContractSize --defaultBalanceEther 5000000
$ yarn test
```

To run coverage

```bash
$ make
$ yarn ganache-cli --gasLimit 50000000 --gasPrice 0 --allowUnlimitedContractSize --defaultBalanceEther 5000000
$ yarn truffle run coverage
```

### Contracts

Solidity smart contracts are found in `./contracts/`.
`./contracts/test` folder contains mock contracts that are used for testing purposes.

## Test Coverage

```text
  Contract: SFC
    Nde
      ✓ Should migrate to New address (67ms)
      ✓ Should not migrate if not owner (56ms)
      ✓ Should not copyCode if not owner (41ms)
      ✓ Should copyCode (49ms)
      ✓ Should not copyCode if not SFC address (43ms)
      ✓ Should update network version (43ms)
      ✓ Should not update network version if not owner (38ms)
      ✓ Should advance epoch
      ✓ Should not set a new storage if not backend address (43ms)
      ✓ Should not advance epoch if not owner (43ms)
      ✓ Should not set backend if not backend address
      ✓ Should not swap code if not backend address (40ms)
      ✓ Should not be possible add a Genesis Validator through NodeDriver if not called by Node (55ms)
      ✓ Should not be possible to deactivate a validator through NodeDriver if not called by Node (40ms)
      ✓ Should not be possible to add a Genesis Delegation through NodeDriver if not called by node
      ✓ Should not be possible to seal Epoch Validators through NodeDriver if not called by node
      ✓ Should not be possible to seal Epoch through NodeDriver if not called by node (40ms)
    Genesis Validator
      ✓ Set Genesis Validator with bad Status (44ms)
      ✓ should reject sealEpoch if not called by Node
      ✓ should reject SealEpochValidators if not called by Node

  Contract: SFC
    Basic functions
      Constants
        ✓ Returns current Epoch
        ✓ Returns minimum amount to stake for a Validator
        ✓ Returns the maximum ratio of delegations a validator can have
        ✓ Returns commission fee in percentage a validator will get from a delegation
        ✓ Returns commission fee in percentage a validator will get from a contract
        ✓ Returns the ratio of the reward rate at base rate (without lockup)
        ✓ Returns the minimum duration of a stake/delegation lockup
        ✓ Returns the maximum duration of a stake/delegation lockup
        ✓ Returns the period of time that stake is locked
        ✓ Returns the number of epochs that stake is locked
        ✓ Returns the version of the current implementation
        ✓ Should create a Validator and return the ID (99ms)
        ✓ Should fail to create a Validator insufficient self-stake (39ms)
        ✓ Should fail if pubkey is empty (40ms)
        ✓ Should create two Validators and return the correct last validator ID (193ms)
        ✓ Should return Delegation (118ms)
        ✓ Should reject if amount is insufficient for self-stake (61ms)
        ✓ Returns current Epoch
        ✓ Should return current Sealed Epoch
        ✓ Should return Now()
        ✓ Should return getTime()
      Initialize
        ✓ Should have been initialized with firstValidator
      Ownable
        ✓ Should return the owner of the contract
        ✓ Should return true if the caller is the owner of the contract
        ✓ Should return address(0) if owner leaves the contract without owner (58ms)
        ✓ Should transfer ownership to the new owner (60ms)
        ✓ Should not be able to transfer ownership if not owner
        ✓ Should not be able to transfer ownership to address(0)
      Events emitters
        ✓ Should call updateNetworkRules
        ✓ Should call updateOfflinePenaltyThreshold

  Contract: SFC
    Prevent Genesis Call if not node
      ✓ Should not be possible add a Genesis Validator if called not by node (53ms)
      ✓ Should not be possible add a Genesis Delegation if called not by node
    Create validators
      ✓ Should create Validators (216ms)
      ✓ Should return the right ValidatorID by calling getValidatorID (275ms)
      ✓ Should not be able to stake if Validator not created yet (307ms)
      ✓ Should stake with different delegators (403ms)
      ✓ Should return the amount of delegated for each Delegator (704ms)
      ✓ Should return the total of received Stake (238ms)
      ✓ Should return the total of received Stake (232ms)

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
      ✓ Returns stashedRewardsUntilEpoch (267ms)
    Methods tests
      ✓ checking createValidator function (395ms)
      ✓ checking sealing epoch (481ms)

  Contract: SFC
    Staking / Sealed Epoch functions
      ✓ Should return claimed Rewards until Epoch (458ms)
      ✓ Check pending Rewards of delegators (333ms)
      ✓ Check if pending Rewards have been increased after sealing Epoch (466ms)
      ✓ Should increase balances after claiming Rewards (415ms)
      ✓ Should increase stake after restaking Rewards (562ms)
      ✓ Should increase locked stake after restaking Rewards (643ms)
      ✓ Should return stashed Rewards (411ms)
      ✓ Should update the validator on node (48ms)
      ✓ Should not be able to deactivate validator if not Node (61ms)
      ✓ Should seal Epochs (187ms)
      ✓ Should seal Epoch on Validators (167ms)
    Stake lockup
      ✓ Check pending Rewards of delegators (301ms)
      ✓ Check if pending Rewards have been increased after sealing Epoch (473ms)
      ✓ Should increase balances after claiming Rewards (440ms)
      ✓ Should return stashed Rewards (438ms)
      ✓ Should return pending rewards after unlocking and re-locking (3653ms)
    NodeDriver
      ✓ Should not be able to call `setGenesisValidator` if not NodeDriver (45ms)
      ✓ Should not be able to call `setGenesisDelegation` if not NodeDriver
      ✓ Should not be able to call `deactivateValidator` if not NodeDriver
      ✓ Should not be able to call `deactivateValidator` with wrong status (40ms)
      ✓ Should deactivate Validator (41ms)
      ✓ Should not be able to call `sealEpochValidators` if not NodeDriver
      ✓ Should not be able to call `sealEpoch` if not NodeDriver (68ms)
    Epoch getters
      ✓ should return EpochvalidatorIds
      ✓ should return the Epoch Received Stake
      ✓ should return the Epoch Accumulated Reward Per Token
      ✓ should return the Epoch Accumulated Uptime
      ✓ should return the Epoch Accumulated Originated Txs Fee
      ✓ should return the Epoch Offline time 
      ✓ should return Epoch Offline Blocks
    Unlock features
      ✓ should fail if trying to unlock stake if not lockedup
      ✓ should fail if trying to unlock stake if amount is 0
false
      ✓ should return if slashed
      ✓ should fail if delegating to an unexisting validator (40ms)
      ✓ should fail if delegating to an unexisting validator (2)
    SFC Rewards getters / Features
<BN: 0>
      ✓ should return stashed rewards
<BN: 0>
      ✓ should return locked stake
<BN: 0>
      ✓ should return locked stake (2)

  Contract: SFC
    Staking / Sealed Epoch functions
      ✓ Should setGenesisDelegation Validator (64ms)

  Contract: SFC
    Test Rewards Calculation
      ✓ Calculation of validators rewards should be equal to 30% (245ms)
      ✓ Should not be able withdraw if request does not exist
      ✓ Should not be able to undelegate 0 amount (246ms)
      ✓ Should not be able to undelegate if not enough unlocked stake (246ms)
      ✓ Should not be able to unlock if not enough unlocked stake (302ms)
      ✓ should return the unlocked stake (220ms)
      ✓ Should not be able to claim Rewards if 0 rewards (515ms)

  Contract: SFC
    Test Calculation Rewards with Lockup
      ✓ Should not be able to lock 0 amount (218ms)
      ✓ Should not be able to lock more than a year (270ms)
      ✓ Should not be able to lock more than validator lockup period (273ms)
      ✓ Should not be able to lock more than validator lockup period (260ms)
      ✓ Should be able to lock for 1 month (417ms)
      ✓ Should not unlock if not locked up FTM (453ms)
      ✓ Should not be able to unlock more than locked stake (464ms)
      ✓ Should unlock after period ended and stash rewards (834ms)

  Contract: SFC
    Test Rewards with lockup Calculation
      ✓ Should not update slashing refund ratio (377ms)
      ✓ Should not sync if validator does not exist


  125 passing (2m)

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
 sfc/                    |    80.56 |    60.11 |    78.74 |    80.21 |                |
  NetworkInitializer.sol |        0 |      100 |        0 |        0 |    31,32,34,40 |
  NodeDriver.sol         |    60.87 |       50 |    57.89 |    58.82 |... 306,313,322 |
  SFC.sol                |    86.08 |    64.46 |       92 |    86.07 |... 5,1456,1481 |
  StakeTokenizer.sol     |        0 |        0 |        0 |        0 |... 52,57,60,68 |
  StakersConstants.sol   |      100 |      100 |      100 |      100 |                |
 test/                   |      100 |      100 |       80 |      100 |                |
  SFCI.sol               |      100 |      100 |      100 |      100 |                |
  StubEvmWriter.sol      |      100 |      100 |       40 |      100 |                |
  UnitTestSFC.sol        |      100 |      100 |      100 |      100 |                |
 version/                |      100 |      100 |      100 |      100 |                |
  Version.sol            |      100 |      100 |      100 |      100 |                |
-------------------------|----------|----------|----------|----------|----------------|
All files                |    73.06 |    55.86 |    66.49 |    72.82 |                |
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
