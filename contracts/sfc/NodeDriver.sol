pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/Initializable.sol";
import "../ownership/Ownable.sol";
import "./SFC.sol";

/**
 * @title NodeDriverAuth
 * @notice System node contract
 */
contract NodeDriverAuth is Initializable, Ownable {
    using SafeMath for uint256;

    SFC internal sfc;
    NodeDriver internal driver;

    /**
     * @dev Initialize NodeDriverAuth, NodeDriver and SFC in one call to allow fewer genesis transactions
     * @param _sfc SFC contract address
     * @param _driver NodeDriver contract address
     * @param _owner Owner
     */
    function initialize(
        address _sfc,
        address _driver,
        address _owner
    ) external initializer {
        Ownable.initialize(_owner);
        driver = NodeDriver(_driver);
        sfc = SFC(_sfc);
    }

    modifier onlySFC() {
        require(msg.sender == address(sfc), "caller is not the SFC contract");
        _;
    }

    modifier onlyDriver() {
        require(
            msg.sender == address(driver),
            "caller is not the NodeDriver contract"
        );
        _;
    }

    /**
     * @dev Changing nodeDriverAuth contract address in NodeDriver contract
     * @param newDriverAuth New NodeDriverAuth contract address
     */
    function migrateTo(address newDriverAuth) external onlyOwner {
        driver.setBackend(newDriverAuth);
    }

    /**
     * @dev Incrementing native balance
     * @param acc Address to increment
     * @param diff How much to increase
     */
    function incBalance(address acc, uint256 diff) external onlySFC {
        require(acc == address(sfc), "recipient is not the SFC contract");
        driver.setBalance(acc, address(acc).balance.add(diff));
    }

    /**
     * @dev Upgrading a code of the contract
     * @param acc Contract's address to upgrade
     * @param from Address of the contract whose code is used for the upgrade
     */
    function upgradeCode(address acc, address from) external onlyOwner {
        require(isContract(acc) && isContract(from), "not a contract");
        driver.copyCode(acc, from);
    }

    /**
     * @dev Upgrading a code of the contract
     * @param acc Contract's address to upgrade
     * @param from Address of the contract whose code is used for the upgrade
     */
    function copyCode(address acc, address from) external onlyOwner {
        driver.copyCode(acc, from);
    }

    /**
     * @dev Incrementing a nonce
     * @param acc Address to increment it's nonce
     * @param diff How much to increase
     */
    function incNonce(address acc, uint256 diff) external onlyOwner {
        driver.incNonce(acc, diff);
    }

    /**
     * @dev Updating the network rules
     * @param diff Network rules diff
     */
    function updateNetworkRules(bytes calldata diff) external onlyOwner {
        driver.updateNetworkRules(diff);
    }

    /**
     * @dev Updating the network version
     * @param version New network version
     */
    function updateNetworkVersion(uint256 version) external onlyOwner {
        driver.updateNetworkVersion(version);
    }

    /**
     * @dev Advancing the number of epochs
     * @param num New network version
     */
    function advanceEpochs(uint256 num) external onlyOwner {
        driver.advanceEpochs(num);
    }

    /**
     * @dev Updating the value of validator weight
     * @param validatorID Validator ID
     * @param value Validator weight
     */
    function updateValidatorWeight(uint256 validatorID, uint256 value)
        external
        onlySFC
    {
        driver.updateValidatorWeight(validatorID, value);
    }

    /**
     * @dev Updating the validator pubkey
     * @param validatorID Validator ID
     * @param pubkey Validator pubkey
     */
    function updateValidatorPubkey(uint256 validatorID, bytes calldata pubkey)
        external
        onlySFC
    {
        driver.updateValidatorPubkey(validatorID, pubkey);
    }

    /**
     * @dev Setting genesis validator
     * @param _auth Validator auth
     * @param validatorID Validator ID
     * @param pubkey Validator pubkey
     * @param status Validator status
     * @param createdEpoch The creation epoch
     * @param createdTime The creation time
     * @param deactivatedEpoch The deactivation epoch
     * @param deactivatedTime The deactivation time
     */
    function setGenesisValidator(
        address _auth,
        uint256 validatorID,
        bytes calldata pubkey,
        uint256 status,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    ) external onlyDriver {
        sfc.setGenesisValidator(
            _auth,
            validatorID,
            pubkey,
            status,
            createdEpoch,
            createdTime,
            deactivatedEpoch,
            deactivatedTime
        );
    }

    /**
     * @dev Setting genesis delegation to validator
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     * @param stake Stake amount
     * @param lockedStake Locked stake amount
     * @param lockupFromEpoch Lockup from epoch
     * @param lockupEndTime Lockup end time
     * @param lockupDuration Lockup duration
     * @param earlyUnlockPenalty Early unlock penalty amount
     * @param rewards Rewards amount
     */
    function setGenesisDelegation(
        address delegator,
        uint256 toValidatorID,
        uint256 stake,
        uint256 lockedStake,
        uint256 lockupFromEpoch,
        uint256 lockupEndTime,
        uint256 lockupDuration,
        uint256 earlyUnlockPenalty,
        uint256 rewards
    ) external onlyDriver {
        sfc.setGenesisDelegation(
            delegator,
            toValidatorID,
            stake,
            lockedStake,
            lockupFromEpoch,
            lockupEndTime,
            lockupDuration,
            earlyUnlockPenalty,
            rewards
        );
    }

    /**
     * @dev Deactivating the validator
     * @param validatorID Validator ID
     * @param status New validator status
     */
    function deactivateValidator(uint256 validatorID, uint256 status)
        external
        onlyDriver
    {
        sfc.deactivateValidator(validatorID, status);
    }

    /**
     * @dev Sealing the epoch info for validators
     * @param nextValidatorIDs Validator IDs
     */
    function sealEpochValidators(uint256[] calldata nextValidatorIDs)
        external
        onlyDriver
    {
        sfc.sealEpochValidators(nextValidatorIDs);
    }

    /**
     * @dev Sealing the info about epoch
     * @param offlineTimes Validators offline time
     * @param offlineBlocks Validators offline blocks
     * @param uptimes Validators uptimes
     * @param originatedTxsFee Fees info
     */
    function sealEpoch(
        uint256[] calldata offlineTimes,
        uint256[] calldata offlineBlocks,
        uint256[] calldata uptimes,
        uint256[] calldata originatedTxsFee
    ) external onlyDriver {
        sfc.sealEpoch(offlineTimes, offlineBlocks, uptimes, originatedTxsFee);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/**
 * @title NodeDriver
 * @notice System node contract
 */
contract NodeDriver is Initializable {
    SFC internal sfc;
    NodeDriver internal backend;
    EVMWriter internal evmWriter;

    event UpdatedBackend(address indexed backend);

    /**
     * @dev Setting new NodeDriverAuth contract
     * @param _backend NodeDriverAuth contract
     */
    function setBackend(address _backend) external onlyBackend {
        emit UpdatedBackend(_backend);
        backend = NodeDriver(_backend);
    }

    modifier onlyBackend() {
        require(msg.sender == address(backend), "caller is not the backend");
        _;
    }

    event UpdateValidatorWeight(uint256 indexed validatorID, uint256 weight);
    event UpdateValidatorPubkey(uint256 indexed validatorID, bytes pubkey);

    event UpdateNetworkRules(bytes diff);
    event UpdateNetworkVersion(uint256 version);
    event AdvanceEpochs(uint256 num);

    /**
     * @dev Initializing the NodeDriver contract
     * @param _backend NodeDriverAuth contract
     * @param _evmWriterAddress EVMWriter contract
     */
    function initialize(address _backend, address _evmWriterAddress)
        external
        initializer
    {
        backend = NodeDriver(_backend);
        emit UpdatedBackend(_backend);
        evmWriter = EVMWriter(_evmWriterAddress);
    }

    /**
     * @dev Setting native balance
     * @param acc Address to set
     * @param value How much to set
     */
    function setBalance(address acc, uint256 value) external onlyBackend {
        evmWriter.setBalance(acc, value);
    }

    /**
     * @dev Upgrading a code of the contract
     * @param acc Contract's address to upgrade
     * @param from Address of the contract whose code is used for the upgrade
     */
    function copyCode(address acc, address from) external onlyBackend {
        evmWriter.copyCode(acc, from);
    }

    /**
     * @dev Upgrading a code of the contract
     * @param acc Contract's address to upgrade
     * @param with Address of the contract whose code is used for the upgrade
     */
    function swapCode(address acc, address with) external onlyBackend {
        evmWriter.swapCode(acc, with);
    }

    /**
     * @dev Setting a value in storage slot
     * @param acc Contract address
     * @param key Storage slot
     * @param value Value to set
     */
    function setStorage(
        address acc,
        bytes32 key,
        bytes32 value
    ) external onlyBackend {
        evmWriter.setStorage(acc, key, value);
    }

    /**
     * @dev Incrementing a nonce
     * @param acc Address to increment it's nonce
     * @param diff How much to increase
     */
    function incNonce(address acc, uint256 diff) external onlyBackend {
        evmWriter.incNonce(acc, diff);
    }

    /**
     * @dev Updating the network rules
     * @param diff Network rules diff
     */
    function updateNetworkRules(bytes calldata diff) external onlyBackend {
        emit UpdateNetworkRules(diff);
    }

    /**
     * @dev Updating the network version
     * @param version New network version
     */
    function updateNetworkVersion(uint256 version) external onlyBackend {
        emit UpdateNetworkVersion(version);
    }

    /**
     * @dev Advancing the number of epochs
     * @param num New network version
     */
    function advanceEpochs(uint256 num) external onlyBackend {
        emit AdvanceEpochs(num);
    }

    /**
     * @dev Updating the value of validator weight
     * @param validatorID Validator ID
     * @param value Validator weight
     */
    function updateValidatorWeight(uint256 validatorID, uint256 value)
        external
        onlyBackend
    {
        emit UpdateValidatorWeight(validatorID, value);
    }

    /**
     * @dev Updating the validator pubkey
     * @param validatorID Validator ID
     * @param pubkey Validator pubkey
     */
    function updateValidatorPubkey(uint256 validatorID, bytes calldata pubkey)
        external
        onlyBackend
    {
        emit UpdateValidatorPubkey(validatorID, pubkey);
    }

    modifier onlyNode() {
        require(msg.sender == address(0), "not callable");
        _;
    }

    // Methods which are called only by the node

    /**
     * @dev Setting genesis validator
     * @param _auth Validator auth
     * @param validatorID Validator ID
     * @param pubkey Validator pubkey
     * @param status Validator status
     * @param createdEpoch The creation epoch
     * @param createdTime The creation time
     * @param deactivatedEpoch The deactivation epoch
     * @param deactivatedTime The deactivation time
     */
    function setGenesisValidator(
        address _auth,
        uint256 validatorID,
        bytes calldata pubkey,
        uint256 status,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    ) external onlyNode {
        backend.setGenesisValidator(
            _auth,
            validatorID,
            pubkey,
            status,
            createdEpoch,
            createdTime,
            deactivatedEpoch,
            deactivatedTime
        );
    }

    /**
     * @dev Setting genesis delegation to validator
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     * @param stake Stake amount
     * @param lockedStake Locked stake amount
     * @param lockupFromEpoch Lockup from epoch
     * @param lockupEndTime Lockup end time
     * @param lockupDuration Lockup duration
     * @param earlyUnlockPenalty Early unlock penalty amount
     * @param rewards Rewards amount
     */
    function setGenesisDelegation(
        address delegator,
        uint256 toValidatorID,
        uint256 stake,
        uint256 lockedStake,
        uint256 lockupFromEpoch,
        uint256 lockupEndTime,
        uint256 lockupDuration,
        uint256 earlyUnlockPenalty,
        uint256 rewards
    ) external onlyNode {
        backend.setGenesisDelegation(
            delegator,
            toValidatorID,
            stake,
            lockedStake,
            lockupFromEpoch,
            lockupEndTime,
            lockupDuration,
            earlyUnlockPenalty,
            rewards
        );
    }

    /**
     * @dev Deactivating the validator
     * @param validatorID Validator ID
     * @param status New validator status
     */
    function deactivateValidator(uint256 validatorID, uint256 status)
        external
        onlyNode
    {
        backend.deactivateValidator(validatorID, status);
    }

    /**
     * @dev Sealing the epoch info for validators
     * @param nextValidatorIDs Validator IDs
     */
    function sealEpochValidators(uint256[] calldata nextValidatorIDs)
        external
        onlyNode
    {
        backend.sealEpochValidators(nextValidatorIDs);
    }

    /**
     * @dev Sealing the info about epoch
     * @param offlineTimes Validators offline time
     * @param offlineBlocks Validators offline blocks
     * @param uptimes Validators uptimes
     * @param originatedTxsFee Fees info
     */
    function sealEpoch(
        uint256[] calldata offlineTimes,
        uint256[] calldata offlineBlocks,
        uint256[] calldata uptimes,
        uint256[] calldata originatedTxsFee
    ) external onlyNode {
        backend.sealEpoch(
            offlineTimes,
            offlineBlocks,
            uptimes,
            originatedTxsFee
        );
    }
}

interface EVMWriter {
    function setBalance(address acc, uint256 value) external;

    function copyCode(address acc, address from) external;

    function swapCode(address acc, address with) external;

    function setStorage(
        address acc,
        bytes32 key,
        bytes32 value
    ) external;

    function incNonce(address acc, uint256 diff) external;
}
