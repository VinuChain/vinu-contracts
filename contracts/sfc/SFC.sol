pragma experimental ABIEncoderV2;
pragma solidity 0.5.17;

import "../common/Initializable.sol";
import "../ownership/Ownable.sol";
import "./StakersConstants.sol";
import "../version/Version.sol";

import "../common/Decimal.sol";
import "./NodeDriver.sol";

/**
 * @title SFC
 * @dev Maintains a group of validators and their delegations
 */
contract SFC is Initializable, Ownable, StakersConstants, Version {
    using SafeMath for uint256;

    uint256 public constant MIN_OFFLINE_PENALTY_THRESHOLD_TIME = 20 minutes;
    uint256 public constant MIN_OFFLINE_PENALTY_THRESHOLD_BLOCKS_NUM = 20;

    /**
     * @dev The staking for validation
     */
    struct Validator {
        uint256 status;
        uint256 deactivatedTime;
        uint256 deactivatedEpoch;
        uint256 receivedStake;
        uint256 createdEpoch;
        uint256 createdTime;
        address auth;
    }

    NodeDriverAuth internal node;

    uint256 public currentSealedEpoch;
    address public genesisValidator;
    mapping(uint256 => Validator) public getValidator;
    mapping(address => uint256) public getValidatorID;
    mapping(uint256 => bytes) public getValidatorPubkey;

    uint256 public lastValidatorID;
    uint256 public totalStake;
    uint256 public totalActiveStake;
    uint256 public totalSlashedStake;
    uint256 public totalPenalty;

    struct Rewards {
        uint256 lockupExtraReward;
        uint256 lockupBaseReward;
        uint256 unlockedReward;
    }

    mapping(address => mapping(uint256 => Rewards)) internal _rewardsStash; // addr, validatorID -> Rewards

    mapping(address => mapping(uint256 => uint256))
        public stashedRewardsUntilEpoch;

    struct WithdrawalRequest {
        uint256 epoch;
        uint256 time;
        uint256 amount;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => WithdrawalRequest)))
        public getWithdrawalRequest;

    struct LockedDelegation {
        uint256 lockedStake;
        uint256 fromEpoch;
        uint256 endTime;
        uint256 duration;
    }

    mapping(address => mapping(uint256 => uint256)) public getStake;

    mapping(address => mapping(uint256 => LockedDelegation))
        public getLockupInfo;

    mapping(address => mapping(uint256 => Rewards))
        public getStashedLockupRewards;

    struct EpochSnapshot {
        mapping(uint256 => uint256) receivedStake;
        mapping(uint256 => uint256) accumulatedRewardPerToken;
        mapping(uint256 => uint256) accumulatedUptime;
        mapping(uint256 => uint256) accumulatedOriginatedTxsFee;
        mapping(uint256 => uint256) offlineTime;
        mapping(uint256 => uint256) offlineBlocks;
        uint256[] validatorIDs;
        uint256 endTime;
        uint256 epochFee;
        uint256 totalBaseRewardWeight;
        uint256 totalTxRewardWeight;
        uint256 baseRewardPerSecond;
        uint256 totalStake;
        uint256 totalSupply;
    }

    uint256 public baseRewardPerSecond;
    uint256 public totalSupply;
    mapping(uint256 => EpochSnapshot) public getEpochSnapshot;

    uint256 offlinePenaltyThresholdBlocksNum;
    uint256 offlinePenaltyThresholdTime;

    mapping(uint256 => uint256) public slashingRefundRatio; // validator ID -> (slashing refund ratio)

    struct StakeWithoutAmount {
        address delegator;
        uint96 timestamp;
        uint256 validatorId;
    }

    struct Stake {
        address delegator;
        uint96 timestamp;
        uint256 validatorId;
        uint256 amount;
    }

    StakeWithoutAmount[] internal stakes;
    mapping(address => mapping(uint256 => uint256)) internal stakePosition;

    mapping(address => mapping(uint256 => uint256)) internal wrIdCount;

    function isNode(address addr) internal view returns (bool) {
        return addr == address(node);
    }

    modifier onlyDriver() {
        require(
            isNode(msg.sender),
            "caller is not the NodeDriverAuth contract"
        );
        _;
    }

    event CreatedValidator(
        uint256 indexed validatorID,
        address indexed auth,
        uint256 createdEpoch,
        uint256 createdTime
    );
    event DeactivatedValidator(
        uint256 indexed validatorID,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    );
    event ChangedValidatorStatus(uint256 indexed validatorID, uint256 status);
    event Delegated(
        address indexed delegator,
        uint256 indexed toValidatorID,
        uint256 amount
    );
    event Undelegated(
        address indexed delegator,
        uint256 indexed toValidatorID,
        uint256 indexed wrID,
        uint256 amount
    );
    event Withdrawn(
        address indexed delegator,
        uint256 indexed toValidatorID,
        uint256 indexed wrID,
        uint256 amount
    );
    event ClaimedRewards(
        address indexed delegator,
        uint256 indexed toValidatorID,
        uint256 lockupExtraReward,
        uint256 lockupBaseReward,
        uint256 unlockedReward
    );
    event RestakedRewards(
        address indexed delegator,
        uint256 indexed toValidatorID,
        uint256 lockupExtraReward,
        uint256 lockupBaseReward,
        uint256 unlockedReward
    );
    event LockedUpStake(
        address indexed delegator,
        uint256 indexed validatorID,
        uint256 duration,
        uint256 amount
    );
    event UnlockedStake(
        address indexed delegator,
        uint256 indexed validatorID,
        uint256 amount,
        uint256 penalty
    );
    event UpdatedBaseRewardPerSec(uint256 value);
    event UpdatedOfflinePenaltyThreshold(uint256 blocksNum, uint256 period);
    event UpdatedSlashingRefundRatio(
        uint256 indexed validatorID,
        uint256 refundRatio
    );
    event RefundedSlashedLegacyDelegation(
        address indexed delegator,
        uint256 indexed validatorID,
        uint256 amount
    );

    /*
    Getters
    */

    /**
     * @dev Getting current epoch
     * @return Current epoch
     */
    function currentEpoch() public view returns (uint256) {
        return currentSealedEpoch + 1;
    }

    /**
     * @dev Getting IDs of validators in epoch
     * @param epoch Epoch to check
     * @return Validator IDs
     */
    function getEpochValidatorIDs(uint256 epoch)
        external
        view
        returns (uint256[] memory)
    {
        return getEpochSnapshot[epoch].validatorIDs;
    }

    /**
     * @dev Getting epoch's validator received stake
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Amount of received stake
     */
    function getEpochReceivedStake(uint256 epoch, uint256 validatorID)
        external
        view
        returns (uint256)
    {
        return getEpochSnapshot[epoch].receivedStake[validatorID];
    }

    /**
     * @dev Getting epoch's accumulated reward per token
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Epoch's accumulated reward per token
     */
    function getEpochAccumulatedRewardPerToken(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256) {
        return getEpochSnapshot[epoch].accumulatedRewardPerToken[validatorID];
    }

    /**
     * @dev Getting epoch's validator accumulated uptime
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Validator's accumulated uptime
     */
    function getEpochAccumulatedUptime(uint256 epoch, uint256 validatorID)
        external
        view
        returns (uint256)
    {
        return getEpochSnapshot[epoch].accumulatedUptime[validatorID];
    }

    /**
     * @dev Getting epoch's validator accumulated tx fee
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Validator's Epoch's validator accumulated tx fee
     */
    function getEpochAccumulatedOriginatedTxsFee(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256) {
        return getEpochSnapshot[epoch].accumulatedOriginatedTxsFee[validatorID];
    }

    /**
     * @dev Getting epoch's validator offline time
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Validator's Epoch's validator offline time
     */
    function getEpochOfflineTime(uint256 epoch, uint256 validatorID)
        external
        view
        returns (uint256)
    {
        return getEpochSnapshot[epoch].offlineTime[validatorID];
    }

    /**
     * @dev Getting epoch's validator offline blocks
     * @param epoch Epoch to check
     * @param validatorID Validator to check
     * @return Validator's Epoch's validator offline blocks
     */
    function getEpochOfflineBlocks(uint256 epoch, uint256 validatorID)
        external
        view
        returns (uint256)
    {
        return getEpochSnapshot[epoch].offlineBlocks[validatorID];
    }

    /**
     * @dev Getting epoch's delegator rewards stash
     * @param delegator Delegator to check
     * @param validatorID Validator to check
     * @return Validator's epoch's delegator rewards stash
     */
    function rewardsStash(address delegator, uint256 validatorID)
        external
        view
        returns (uint256)
    {
        Rewards memory stash = _rewardsStash[delegator][validatorID];
        return
            stash.lockupBaseReward.add(stash.lockupExtraReward).add(
                stash.unlockedReward
            );
    }

    /**
     * @dev Getting epoch's delegator locked stake
     * @param delegator Delegator to check
     * @param toValidatorID Validator to check
     * @return Validator's Epoch's delegator locked stake
     */
    function getLockedStake(address delegator, uint256 toValidatorID)
        public
        view
        returns (uint256)
    {
        if (!isLockedUp(delegator, toValidatorID)) {
            return 0;
        }
        return getLockupInfo[delegator][toValidatorID].lockedStake;
    }

    /**
     * @dev Getting all stakes info
     * @param offset Offset to start with
     * @param limit Return size limit
     * @return All stakes info
     */
    function getStakes(
        uint256 offset,
        uint256 limit
    ) external view returns (Stake[] memory) {
        uint256 length = stakes.length;
        Stake[] memory stakes_ = new Stake[](limit);
        for (uint256 i = 0; i < limit; ) {
            if (offset.add(i) >= length) break;
            address delegator = stakes[offset + i].delegator;
            uint256 validatorId = stakes[offset + i].validatorId;
            stakes_[i] = Stake({
                delegator: delegator,
                timestamp: stakes[offset + i].timestamp,
                validatorId: validatorId,
                amount: getStake[delegator][validatorId]
            });
            i = i.add(1);
        }
        return stakes_;
    }

    /**
     * @dev Getting withdraw requests info
     * @param delegator Delegator address
     * @param validatorID Validator ID
     * @param offset Offset to start with
     * @param limit Return size limit
     * @return Withdraw requests info
     */
    function getWrRequests(
        address delegator,
        uint256 validatorID,
        uint256 offset,
        uint256 limit
    ) external view returns (WithdrawalRequest[] memory) {
        WithdrawalRequest[] memory requests_ = new WithdrawalRequest[](limit);
        for (uint256 i = 0; i < limit; ) {
            requests_[i] = getWithdrawalRequest[delegator][validatorID][
                offset.add(i)
            ];
            i = i.add(1);
        }
        return requests_;
    }

    /*
    Constructor
    */

    /**
     * @dev Initializing the SFC
     * @param sealedEpoch Current sealed epoch
     * @param _totalSupply Native token total supply
     * @param nodeDriver NodeDriverAuth contract
     * @param owner Owner
     */
    function initialize(
        uint256 sealedEpoch,
        uint256 _totalSupply,
        address nodeDriver,
        address owner
    ) external initializer {
        Ownable.initialize(owner);
        currentSealedEpoch = sealedEpoch;
        node = NodeDriverAuth(nodeDriver);
        totalSupply = _totalSupply;
        baseRewardPerSecond = 0.93 * 1e18;
        offlinePenaltyThresholdBlocksNum = 120;
        offlinePenaltyThresholdTime = 2 hours;
        getEpochSnapshot[sealedEpoch].endTime = _now();

        stakes.push(
            StakeWithoutAmount({
                delegator: address(0),
                validatorId: 0,
                timestamp: 0
            })
        );
    }

    /**
     * @dev Setting genesis validator
     * @param auth Validator auth
     * @param validatorID Validator ID
     * @param pubkey Validator pubkey
     * @param status Validator status
     * @param createdEpoch The creation epoch
     * @param createdTime The creation time
     * @param deactivatedEpoch The deactivation epoch
     * @param deactivatedTime The deactivation time
     */
    function setGenesisValidator(
        address auth,
        uint256 validatorID,
        bytes calldata pubkey,
        uint256 status,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    ) external onlyDriver {
        _rawCreateValidator(
            auth,
            validatorID,
            pubkey,
            status,
            createdEpoch,
            createdTime,
            deactivatedEpoch,
            deactivatedTime
        );
        if (validatorID > lastValidatorID) {
            lastValidatorID = validatorID;
        }
        genesisValidator = auth;
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
        _rawDelegate(delegator, toValidatorID, stake);
        _rewardsStash[delegator][toValidatorID].unlockedReward = rewards;
        _mintNativeToken(stake);
        if (lockedStake != 0) {
            require(
                lockedStake <= stake,
                "locked stake is greater than the whole stake"
            );
            LockedDelegation storage ld = getLockupInfo[delegator][
                toValidatorID
            ];
            ld.lockedStake = lockedStake;
            ld.fromEpoch = lockupFromEpoch;
            ld.endTime = lockupEndTime;
            ld.duration = lockupDuration;
            getStashedLockupRewards[delegator][toValidatorID]
                .lockupExtraReward = earlyUnlockPenalty;
            emit LockedUpStake(
                delegator,
                toValidatorID,
                lockupDuration,
                lockedStake
            );
        }
    }

    /*
    Methods
    */

    /**
     * @dev Creating the validator
     * @param pubkey Validator pubkey
     */
    function createValidator(bytes calldata pubkey) external payable {
        require(msg.value >= minSelfStake(), "insufficient self-stake");
        require(pubkey.length > 0, "empty pubkey");
        _createValidator(msg.sender, pubkey);
        _delegate(msg.sender, lastValidatorID, msg.value);
    }

    function _createValidator(address auth, bytes memory pubkey) internal {
        uint256 validatorID = ++lastValidatorID;
        _rawCreateValidator(
            auth,
            validatorID,
            pubkey,
            OK_STATUS,
            currentEpoch(),
            _now(),
            0,
            0
        );
    }

    function _rawCreateValidator(
        address auth,
        uint256 validatorID,
        bytes memory pubkey,
        uint256 status,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    ) internal {
        require(getValidatorID[auth] == 0, "validator already exists");
        getValidatorID[auth] = validatorID;
        getValidator[validatorID].status = status;
        getValidator[validatorID].createdEpoch = createdEpoch;
        getValidator[validatorID].createdTime = createdTime;
        getValidator[validatorID].deactivatedTime = deactivatedTime;
        getValidator[validatorID].deactivatedEpoch = deactivatedEpoch;
        getValidator[validatorID].auth = auth;
        getValidatorPubkey[validatorID] = pubkey;

        emit CreatedValidator(validatorID, auth, createdEpoch, createdTime);
        if (deactivatedEpoch != 0) {
            emit DeactivatedValidator(
                validatorID,
                deactivatedEpoch,
                deactivatedTime
            );
        }
        if (status != 0) {
            emit ChangedValidatorStatus(validatorID, status);
        }
    }

    /**
     * @dev Getting the amount of self stake for validator
     * @param validatorID Validator ID
     * @return Self stake amount
     */
    function getSelfStake(uint256 validatorID) public view returns (uint256) {
        return getStake[getValidator[validatorID].auth][validatorID];
    }

    function _checkDelegatedStakeLimit(uint256 validatorID)
        internal
        view
        returns (bool)
    {
        return
            getValidator[validatorID].receivedStake <=
            getSelfStake(validatorID).mul(maxDelegatedRatio()).div(
                Decimal.unit()
            );
    }

    /**
     * @dev Staking for validator
     * @param toValidatorID Validator ID
     */
    function delegate(uint256 toValidatorID) external payable {
        _delegate(msg.sender, toValidatorID, msg.value);
    }

    function _delegate(
        address delegator,
        uint256 toValidatorID,
        uint256 amount
    ) internal {
        require(_validatorExists(toValidatorID), "validator doesn't exist");
        require(
            getValidator[toValidatorID].status == OK_STATUS,
            "validator isn't active"
        );
        _rawDelegate(delegator, toValidatorID, amount);
        require(
            _checkDelegatedStakeLimit(toValidatorID),
            "validator's delegations limit is exceeded"
        );
    }

    function _rawDelegate(
        address delegator,
        uint256 toValidatorID,
        uint256 amount
    ) internal {
        require(amount > 0, "zero amount");

        _stashRewards(delegator, toValidatorID);

        uint256 stakePos = stakePosition[delegator][toValidatorID];
        if (stakePos == 0) {
            stakePosition[delegator][toValidatorID] = stakes.length;
            stakes.push(
                StakeWithoutAmount({
                    delegator: delegator,
                    timestamp: uint96(block.timestamp),
                    validatorId: toValidatorID
                })
            );
        } else {
            stakes[stakePos].timestamp = uint96(block.timestamp);
        }

        getStake[delegator][toValidatorID] = getStake[delegator][toValidatorID]
            .add(amount);
        uint256 origStake = getValidator[toValidatorID].receivedStake;
        getValidator[toValidatorID].receivedStake = origStake.add(amount);
        totalStake = totalStake.add(amount);
        if (getValidator[toValidatorID].status == OK_STATUS) {
            totalActiveStake = totalActiveStake.add(amount);
        }

        _syncValidator(toValidatorID, origStake == 0);

        emit Delegated(delegator, toValidatorID, amount);
    }

    function _setValidatorDeactivated(uint256 validatorID, uint256 status)
        internal
    {
        if (
            getValidator[validatorID].status == OK_STATUS && status != OK_STATUS
        ) {
            totalActiveStake = totalActiveStake.sub(
                getValidator[validatorID].receivedStake
            );
        }
        // status as a number is proportional to severity
        if (status > getValidator[validatorID].status) {
            getValidator[validatorID].status = status;
            if (getValidator[validatorID].deactivatedEpoch == 0) {
                getValidator[validatorID].deactivatedEpoch = currentEpoch();
                getValidator[validatorID].deactivatedTime = _now();
                emit DeactivatedValidator(
                    validatorID,
                    getValidator[validatorID].deactivatedEpoch,
                    getValidator[validatorID].deactivatedTime
                );
            }
            emit ChangedValidatorStatus(validatorID, status);
        }
    }

    function _rawUndelegate(
        address delegator,
        uint256 toValidatorID,
        uint256 amount
    ) internal {
        getStake[delegator][toValidatorID] = getStake[delegator][toValidatorID].sub(amount);
        getValidator[toValidatorID].receivedStake = getValidator[toValidatorID]
            .receivedStake
            .sub(amount);
        totalStake = totalStake.sub(amount);

        if (getStake[delegator][toValidatorID] == 0) {
            uint256 stakePos = stakePosition[delegator][toValidatorID];
            _removeStake(stakePos);
        }

        if (getValidator[toValidatorID].status == OK_STATUS) {
            totalActiveStake = totalActiveStake.sub(amount);
        }

        uint256 selfStakeAfterwards = getSelfStake(toValidatorID);
        if (selfStakeAfterwards != 0) {
            if (getValidator[toValidatorID].status == OK_STATUS) {
                require(
                    selfStakeAfterwards >= minSelfStake(),
                    "insufficient self-stake"
                );
                require(
                    _checkDelegatedStakeLimit(toValidatorID),
                    "validator's delegations limit is exceeded"
                );
            }
        } else {
            _setValidatorDeactivated(toValidatorID, WITHDRAWN_BIT);
        }
    }

    function _removeStake(uint256 position) internal {
        uint256 stakesLength = stakes.length;
        assert(position < stakesLength);

        uint256 lastPos = stakesLength.sub(1);
        if (position != lastPos) {
            stakes[position] = stakes[lastPos];

            stakePosition[stakes[lastPos].delegator][
                stakes[lastPos].validatorId
            ] = position;
        }
        stakes.pop();

        assert(stakesLength - 1 != 0);
    }

    /**
     * @dev Unstaking amount for validator (without withdraw)
     * @param toValidatorID Validator ID
     * @param amount Amount to unstake
     */
    function undelegate(
        uint256 toValidatorID,
        uint256 amount
    ) external {
        address delegator = msg.sender;

        _stashRewards(delegator, toValidatorID);

        require(amount > 0, "zero amount");
        require(
            amount <= getUnlockedStake(delegator, toValidatorID),
            "not enough unlocked stake"
        );

        uint256 wrID = wrIdCount[delegator][toValidatorID]++;

        _rawUndelegate(delegator, toValidatorID, amount);

        getWithdrawalRequest[delegator][toValidatorID][wrID].amount = amount;
        getWithdrawalRequest[delegator][toValidatorID][wrID]
            .epoch = currentEpoch();
        getWithdrawalRequest[delegator][toValidatorID][wrID].time = _now();

        _syncValidator(toValidatorID, false);

        emit Undelegated(delegator, toValidatorID, wrID, amount);
    }

    /**
     * @dev If the validator is slashed, there is a penalty for withdraw
     * @param validatorID Validator ID
     * @return Is the validator slashed
     */
    function isSlashed(uint256 validatorID) public view returns (bool) {
        return getValidator[validatorID].status & CHEATER_MASK != 0;
    }

    function getSlashingPenalty(
        uint256 amount,
        bool isCheater,
        uint256 refundRatio
    ) internal pure returns (uint256 penalty) {
        if (!isCheater || refundRatio >= Decimal.unit()) {
            return 0;
        }
        // round penalty upwards (ceiling) to prevent dust amount attacks
        penalty = amount
            .mul(Decimal.unit() - refundRatio)
            .div(Decimal.unit())
            .add(1);
        if (penalty > amount) {
            return amount;
        }
        return penalty;
    }

    /**
     * @dev Withdrawing unstaked amount
     * @param toValidatorID Validator ID
     * @param wrID Undelegate request ID
     */
    function withdraw(uint256 toValidatorID, uint256 wrID) external {
        address payable delegator = msg.sender;
        WithdrawalRequest memory request = getWithdrawalRequest[delegator][
            toValidatorID
        ][wrID];
        require(request.epoch != 0, "request doesn't exist");

        uint256 requestTime = request.time;
        uint256 requestEpoch = request.epoch;
        if (
            getValidator[toValidatorID].deactivatedTime != 0 &&
            getValidator[toValidatorID].deactivatedTime < requestTime
        ) {
            requestTime = getValidator[toValidatorID].deactivatedTime;
            requestEpoch = getValidator[toValidatorID].deactivatedEpoch;
        }

        uint256 wPeriodTime;
        uint256 wPeriodEpochs;
        if (getValidatorID[delegator] == 0 && delegator != genesisValidator) {
            wPeriodTime = withdrawalPeriodTime();
            wPeriodEpochs = withdrawalPeriodEpochs();
        } else {
            wPeriodTime = withdrawalPeriodTimeValidator();
            wPeriodEpochs = withdrawalPeriodEpochsValidator();
        }
        require(
            _now() >= requestTime + wPeriodTime,
            "not enough time passed"
        );
        require(
            currentEpoch() >= requestEpoch + wPeriodEpochs,
            "not enough epochs passed"
        );

        uint256 amount = getWithdrawalRequest[delegator][toValidatorID][wrID]
            .amount;
        bool isCheater = isSlashed(toValidatorID);
        uint256 penalty = getSlashingPenalty(
            amount,
            isCheater,
            slashingRefundRatio[toValidatorID]
        );
        delete getWithdrawalRequest[delegator][toValidatorID][wrID];

        if (penalty != 0) {
            totalSlashedStake = totalSlashedStake.add(penalty);
            totalPenalty = totalPenalty.add(penalty);
        }
        require(amount > penalty, "stake is fully slashed");
        // It's important that we transfer after erasing (protection against Re-Entrancy)
        (bool sent, ) = delegator.call.value(amount.sub(penalty))("");
        require(sent, "Failed to send VC");

        emit Withdrawn(delegator, toValidatorID, wrID, amount);
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
        require(status != OK_STATUS, "wrong status");

        _setValidatorDeactivated(validatorID, status);
        _syncValidator(validatorID, false);
    }

    function _calcRawValidatorEpochBaseReward(
        uint256 epochDuration,
        uint256 _baseRewardPerSecond,
        uint256 baseRewardWeight,
        uint256 totalBaseRewardWeight
    ) internal pure returns (uint256) {
        if (baseRewardWeight == 0) {
            return 0;
        }
        uint256 totalReward = epochDuration.mul(_baseRewardPerSecond);
        return totalReward.mul(baseRewardWeight).div(totalBaseRewardWeight);
    }

    function _calcRawValidatorEpochTxReward(
        uint256 epochFee,
        uint256 txRewardWeight,
        uint256 totalTxRewardWeight
    ) internal pure returns (uint256) {
        if (txRewardWeight == 0) {
            return 0;
        }
        uint256 txReward = epochFee.mul(txRewardWeight).div(
            totalTxRewardWeight
        );
        // fee reward except contractCommission
        return
            txReward.mul(Decimal.unit() - contractCommission()).div(
                Decimal.unit()
            );
    }

    function _calcValidatorCommission(uint256 rawReward, uint256 commission)
        internal
        pure
        returns (uint256)
    {
        return rawReward.mul(commission).div(Decimal.unit());
    }

    function _highestPayableEpoch(uint256 validatorID)
        internal
        view
        returns (uint256)
    {
        if (getValidator[validatorID].deactivatedEpoch != 0) {
            if (
                currentSealedEpoch < getValidator[validatorID].deactivatedEpoch
            ) {
                return currentSealedEpoch;
            }
            return getValidator[validatorID].deactivatedEpoch;
        }
        return currentSealedEpoch;
    }

    // find highest epoch such that _isLockedUpAtEpoch returns true (using binary search)
    function _highestLockupEpoch(address delegator, uint256 validatorID)
        internal
        view
        returns (uint256)
    {
        uint256 l = getLockupInfo[delegator][validatorID].fromEpoch;
        uint256 r = currentSealedEpoch;
        if (_isLockedUpAtEpoch(delegator, validatorID, r)) {
            return r;
        }
        if (!_isLockedUpAtEpoch(delegator, validatorID, l)) {
            return 0;
        }
        if (l > r) {
            return 0;
        }
        while (l < r) {
            uint256 m = (l + r) / 2;
            if (_isLockedUpAtEpoch(delegator, validatorID, m)) {
                l = m + 1;
            } else {
                r = m;
            }
        }
        if (r == 0) {
            return 0;
        }
        return r - 1;
    }

    function _scaleLockupReward(uint256 fullReward, uint256 lockupDuration)
        internal
        pure
        returns (Rewards memory reward)
    {
        reward = Rewards(0, 0, 0);
        if (lockupDuration != 0) {
            uint256 maxLockupExtraRatio = Decimal.unit() -
                unlockedRewardRatio();
            uint256 lockupExtraRatio = maxLockupExtraRatio
                .mul(lockupDuration)
                .div(maxLockupDuration());
            uint256 totalScaledReward = fullReward
                .mul(unlockedRewardRatio() + lockupExtraRatio)
                .div(Decimal.unit());
            reward.lockupBaseReward = fullReward.mul(unlockedRewardRatio()).div(
                Decimal.unit()
            );
            reward.lockupExtraReward =
                totalScaledReward -
                reward.lockupBaseReward;
        } else {
            reward.unlockedReward = fullReward.mul(unlockedRewardRatio()).div(
                Decimal.unit()
            );
        }
        return reward;
    }

    function sumRewards(Rewards memory a, Rewards memory b)
        internal
        pure
        returns (Rewards memory)
    {
        return
            Rewards(
                a.lockupExtraReward.add(b.lockupExtraReward),
                a.lockupBaseReward.add(b.lockupBaseReward),
                a.unlockedReward.add(b.unlockedReward)
            );
    }

    function sumRewards(
        Rewards memory a,
        Rewards memory b,
        Rewards memory c
    ) internal pure returns (Rewards memory) {
        return sumRewards(sumRewards(a, b), c);
    }

    function _newRewards(address delegator, uint256 toValidatorID)
        internal
        view
        returns (Rewards memory)
    {
        uint256 stashedUntil = stashedRewardsUntilEpoch[delegator][
            toValidatorID
        ];
        uint256 payableUntil = _highestPayableEpoch(toValidatorID);
        uint256 lockedUntil = _highestLockupEpoch(delegator, toValidatorID);
        if (lockedUntil > payableUntil) {
            lockedUntil = payableUntil;
        }
        if (lockedUntil < stashedUntil) {
            lockedUntil = stashedUntil;
        }

        LockedDelegation storage ld = getLockupInfo[delegator][toValidatorID];
        uint256 wholeStake = getStake[delegator][toValidatorID];
        uint256 unlockedStake = wholeStake.sub(ld.lockedStake);
        uint256 fullReward;

        // count reward for locked stake during lockup epochs
        fullReward = _newRewardsOf(
            ld.lockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory plReward = _scaleLockupReward(fullReward, ld.duration);
        // count reward for unlocked stake during lockup epochs
        fullReward = _newRewardsOf(
            unlockedStake,
            toValidatorID,
            stashedUntil,
            lockedUntil
        );
        Rewards memory puReward = _scaleLockupReward(fullReward, 0);
        // count lockup reward for unlocked stake during unlocked epochs
        fullReward = _newRewardsOf(
            wholeStake,
            toValidatorID,
            lockedUntil,
            payableUntil
        );
        Rewards memory wuReward = _scaleLockupReward(fullReward, 0);

        return sumRewards(plReward, puReward, wuReward);
    }

    function _newRewardsOf(
        uint256 stakeAmount,
        uint256 toValidatorID,
        uint256 fromEpoch,
        uint256 toEpoch
    ) internal view returns (uint256) {
        if (fromEpoch >= toEpoch) {
            return 0;
        }
        uint256 stashedRate = getEpochSnapshot[fromEpoch]
            .accumulatedRewardPerToken[toValidatorID];
        uint256 currentRate = getEpochSnapshot[toEpoch]
            .accumulatedRewardPerToken[toValidatorID];
        return
            currentRate.sub(stashedRate).mul(stakeAmount).div(Decimal.unit());
    }

    function _pendingRewards(address delegator, uint256 toValidatorID)
        internal
        view
        returns (Rewards memory)
    {
        Rewards memory reward = _newRewards(delegator, toValidatorID);
        return sumRewards(_rewardsStash[delegator][toValidatorID], reward);
    }

    /**
     * @dev Getting the amount of pending rewards for validator
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     * @return Amount of pending rewards
     */
    function pendingRewards(address delegator, uint256 toValidatorID)
        external
        view
        returns (uint256)
    {
        Rewards memory reward = _pendingRewards(delegator, toValidatorID);
        return
            reward.unlockedReward.add(reward.lockupBaseReward).add(
                reward.lockupExtraReward
            );
    }

    /**
     * @dev Stashing rewards for validator
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     */
    function stashRewards(address delegator, uint256 toValidatorID) external {
        require(_stashRewards(delegator, toValidatorID), "nothing to stash");
    }

    function _stashRewards(address delegator, uint256 toValidatorID)
        internal
        returns (bool updated)
    {
        Rewards memory nonStashedReward = _newRewards(delegator, toValidatorID);
        stashedRewardsUntilEpoch[delegator][
            toValidatorID
        ] = _highestPayableEpoch(toValidatorID);
        _rewardsStash[delegator][toValidatorID] = sumRewards(
            _rewardsStash[delegator][toValidatorID],
            nonStashedReward
        );
        getStashedLockupRewards[delegator][toValidatorID] = sumRewards(
            getStashedLockupRewards[delegator][toValidatorID],
            nonStashedReward
        );
        if (!isLockedUp(delegator, toValidatorID)) {
            delete getLockupInfo[delegator][toValidatorID];
            delete getStashedLockupRewards[delegator][toValidatorID];
        }
        return
            nonStashedReward.lockupBaseReward != 0 ||
            nonStashedReward.lockupExtraReward != 0 ||
            nonStashedReward.unlockedReward != 0;
    }

    function _mintNativeToken(uint256 amount) internal {
        // balance will be increased after the transaction is processed
        node.incBalance(address(this), amount);
        totalSupply = totalSupply.add(amount);
    }

    function _claimRewards(address delegator, uint256 toValidatorID)
        internal
        returns (Rewards memory rewards)
    {
        _stashRewards(delegator, toValidatorID);
        rewards = _rewardsStash[delegator][toValidatorID];
        uint256 totalReward = rewards
            .unlockedReward
            .add(rewards.lockupBaseReward)
            .add(rewards.lockupExtraReward);
        require(totalReward != 0, "zero rewards");
        delete _rewardsStash[delegator][toValidatorID];
        // It's important that we mint after erasing (protection against Re-Entrancy)
        _mintNativeToken(totalReward);
        return rewards;
    }

    /**
     * @dev Claiming rewards
     * @param toValidatorID Validator ID
     */
    function claimRewards(uint256 toValidatorID) external {
        address payable delegator = msg.sender;
        Rewards memory rewards = _claimRewards(delegator, toValidatorID);
        // It's important that we transfer after erasing (protection against Re-Entrancy)
        (bool sent, ) = delegator.call.value(
            rewards.lockupExtraReward.add(rewards.lockupBaseReward).add(
                rewards.unlockedReward
            )
        )("");
        require(sent, "Failed to send VC");

        emit ClaimedRewards(
            delegator,
            toValidatorID,
            rewards.lockupExtraReward,
            rewards.lockupBaseReward,
            rewards.unlockedReward
        );
    }

    /**
     * @dev Restaking rewards
     * @param toValidatorID Validator ID
     */
    function restakeRewards(uint256 toValidatorID) external {
        address delegator = msg.sender;
        Rewards memory rewards = _claimRewards(delegator, toValidatorID);

        uint256 lockupReward = rewards.lockupExtraReward.add(
            rewards.lockupBaseReward
        );
        _delegate(
            delegator,
            toValidatorID,
            lockupReward.add(rewards.unlockedReward)
        );
        getLockupInfo[delegator][toValidatorID].lockedStake += lockupReward;
        emit RestakedRewards(
            delegator,
            toValidatorID,
            rewards.lockupExtraReward,
            rewards.lockupBaseReward,
            rewards.unlockedReward
        );
    }

    // _syncValidator updates the validator data on node
    function _syncValidator(uint256 validatorID, bool syncPubkey) public {
        require(_validatorExists(validatorID), "validator doesn't exist");
        // emit special log for node
        uint256 weight = getValidator[validatorID].receivedStake;
        if (getValidator[validatorID].status != OK_STATUS) {
            weight = 0;
        }
        node.updateValidatorWeight(validatorID, weight);
        if (syncPubkey && weight != 0) {
            node.updateValidatorPubkey(
                validatorID,
                getValidatorPubkey[validatorID]
            );
        }
    }

    function _validatorExists(uint256 validatorID)
        internal
        view
        returns (bool)
    {
        return getValidator[validatorID].createdTime != 0;
    }

    /**
     * @dev Getting the info about offline penalty threshold
     * @return blocksNum Amount of blocks
     * @return time Threshold time
     */
    function offlinePenaltyThreshold()
        external
        view
        returns (uint256 blocksNum, uint256 time)
    {
        return (offlinePenaltyThresholdBlocksNum, offlinePenaltyThresholdTime);
    }

    /**
     * @dev Updating base validators reward per second value
     * @param value New base reward
     */
    function updateBaseRewardPerSecond(uint256 value) external onlyOwner {
        require(
            value <= 32.967977168935185184 * 1e18,
            "too large reward per second"
        );
        baseRewardPerSecond = value;
        emit UpdatedBaseRewardPerSec(value);
    }

    /**
     * @dev Updating offline penalty threshold blocks and time
     * @param blocksNum Number of blocks
     * @param time Threshold time
     */
    function updateOfflinePenaltyThreshold(uint256 blocksNum, uint256 time)
        external
        onlyOwner
    {
        require(blocksNum >= MIN_OFFLINE_PENALTY_THRESHOLD_BLOCKS_NUM, "too low penalty blocks num");
        require(time >= MIN_OFFLINE_PENALTY_THRESHOLD_TIME, "too low penalty time");
        offlinePenaltyThresholdTime = time;
        offlinePenaltyThresholdBlocksNum = blocksNum;
        emit UpdatedOfflinePenaltyThreshold(blocksNum, time);
    }

    /**
     * @dev Updating slashing refund ratio
     * @param validatorID Validator ID
     * @param refundRatio Refund ratio
     */
    function updateSlashingRefundRatio(uint256 validatorID, uint256 refundRatio)
        external
        onlyOwner
    {
        require(isSlashed(validatorID), "validator isn't slashed");
        require(
            refundRatio <= Decimal.unit(),
            "must be less than or equal to 1.0"
        );
        slashingRefundRatio[validatorID] = refundRatio;
        emit UpdatedSlashingRefundRatio(validatorID, refundRatio);
    }

    function _sealEpoch_offline(
        EpochSnapshot storage snapshot,
        uint256[] memory validatorIDs,
        uint256[] memory offlineTime,
        uint256[] memory offlineBlocks
    ) internal {
        // mark offline nodes
        for (uint256 i = 0; i < validatorIDs.length; i++) {
            if (
                offlineBlocks[i] > offlinePenaltyThresholdBlocksNum &&
                offlineTime[i] >= offlinePenaltyThresholdTime
            ) {
                _setValidatorDeactivated(validatorIDs[i], OFFLINE_BIT);
                _syncValidator(validatorIDs[i], false);
            }
            // log data
            snapshot.offlineTime[validatorIDs[i]] = offlineTime[i];
            snapshot.offlineBlocks[validatorIDs[i]] = offlineBlocks[i];
        }
    }

    struct _SealEpochRewardsCtx {
        uint256[] baseRewardWeights;
        uint256 totalBaseRewardWeight;
        uint256[] txRewardWeights;
        uint256 totalTxRewardWeight;
        uint256 epochDuration;
        uint256 epochFee;
    }

    function _sealEpoch_rewards(
        EpochSnapshot storage snapshot,
        uint256[] memory validatorIDs,
        uint256[] memory uptimes,
        uint256[] memory accumulatedOriginatedTxsFee
    ) internal {
        _SealEpochRewardsCtx memory ctx = _SealEpochRewardsCtx(
            new uint256[](validatorIDs.length),
            0,
            new uint256[](validatorIDs.length),
            0,
            0,
            0
        );
        EpochSnapshot storage prevSnapshot = getEpochSnapshot[
            currentSealedEpoch
        ];

        ctx.epochDuration = 1;
        if (_now() > prevSnapshot.endTime) {
            ctx.epochDuration = _now() - prevSnapshot.endTime;
        }

        for (uint256 i = 0; i < validatorIDs.length; i++) {
            uint256 prevAccumulatedTxsFee = prevSnapshot
                .accumulatedOriginatedTxsFee[validatorIDs[i]];
            uint256 originatedTxsFee = 0;
            if (accumulatedOriginatedTxsFee[i] > prevAccumulatedTxsFee) {
                originatedTxsFee =
                    accumulatedOriginatedTxsFee[i] -
                    prevAccumulatedTxsFee;
            }
            // txRewardWeight = {originatedTxsFee} * {uptime}
            // originatedTxsFee is roughly proportional to {uptime} * {stake}, so the whole formula is roughly
            // {stake} * {uptime} ^ 2
            ctx.txRewardWeights[i] =
                (originatedTxsFee * uptimes[i]) /
                ctx.epochDuration;
            ctx.totalTxRewardWeight = ctx.totalTxRewardWeight.add(
                ctx.txRewardWeights[i]
            );
            ctx.epochFee = ctx.epochFee.add(originatedTxsFee);
        }

        for (uint256 i = 0; i < validatorIDs.length; i++) {
            // baseRewardWeight = {stake} * {uptime ^ 2}
            ctx.baseRewardWeights[i] =
                (((snapshot.receivedStake[validatorIDs[i]] * uptimes[i]) /
                    ctx.epochDuration) * uptimes[i]) /
                ctx.epochDuration;
            ctx.totalBaseRewardWeight = ctx.totalBaseRewardWeight.add(
                ctx.baseRewardWeights[i]
            );
        }

        for (uint256 i = 0; i < validatorIDs.length; i++) {
            uint256 rawReward = _calcRawValidatorEpochBaseReward(
                ctx.epochDuration,
                baseRewardPerSecond,
                ctx.baseRewardWeights[i],
                ctx.totalBaseRewardWeight
            );
            rawReward = rawReward.add(
                _calcRawValidatorEpochTxReward(
                    ctx.epochFee,
                    ctx.txRewardWeights[i],
                    ctx.totalTxRewardWeight
                )
            );

            uint256 validatorID = validatorIDs[i];
            address validatorAddr = getValidator[validatorID].auth;
            // accounting validator's commission
            uint256 commissionRewardFull = _calcValidatorCommission(
                rawReward,
                validatorCommission()
            );
            uint256 selfStake = getStake[validatorAddr][validatorID];
            if (selfStake != 0) {
                uint256 lCommissionRewardFull = (commissionRewardFull *
                    getLockedStake(validatorAddr, validatorID)) / selfStake;
                uint256 uCommissionRewardFull = commissionRewardFull -
                    lCommissionRewardFull;
                Rewards memory lCommissionReward = _scaleLockupReward(
                    lCommissionRewardFull,
                    getLockupInfo[validatorAddr][validatorID].duration
                );
                Rewards memory uCommissionReward = _scaleLockupReward(
                    uCommissionRewardFull,
                    0
                );
                _rewardsStash[validatorAddr][validatorID] = sumRewards(
                    _rewardsStash[validatorAddr][validatorID],
                    lCommissionReward,
                    uCommissionReward
                );
                getStashedLockupRewards[validatorAddr][
                    validatorID
                ] = sumRewards(
                    getStashedLockupRewards[validatorAddr][validatorID],
                    lCommissionReward,
                    uCommissionReward
                );
            }
            // accounting reward per token for delegators
            uint256 delegatorsReward = rawReward - commissionRewardFull;
            // note: use latest stake for the sake of rewards distribution accuracy, not snapshot.receivedStake
            uint256 receivedStake = getValidator[validatorID].receivedStake;
            uint256 rewardPerToken = 0;
            if (receivedStake != 0) {
                rewardPerToken =
                    (delegatorsReward * Decimal.unit()) /
                    receivedStake;
            }
            snapshot.accumulatedRewardPerToken[validatorID] =
                prevSnapshot.accumulatedRewardPerToken[validatorID] +
                rewardPerToken;
            //
            snapshot.accumulatedOriginatedTxsFee[
                validatorID
            ] = accumulatedOriginatedTxsFee[i];
            snapshot.accumulatedUptime[validatorID] =
                prevSnapshot.accumulatedUptime[validatorID] +
                uptimes[i];
        }

        snapshot.epochFee = ctx.epochFee;
        snapshot.totalBaseRewardWeight = ctx.totalBaseRewardWeight;
        snapshot.totalTxRewardWeight = ctx.totalTxRewardWeight;
    }

    /**
     * @dev Sealing the info about epoch
     * @param offlineTime Validators offline time
     * @param offlineBlocks Validators offline blocks
     * @param uptimes Validators uptimes
     * @param originatedTxsFee Fees info
     */
    function sealEpoch(
        uint256[] calldata offlineTime,
        uint256[] calldata offlineBlocks,
        uint256[] calldata uptimes,
        uint256[] calldata originatedTxsFee
    ) external onlyDriver {
        EpochSnapshot storage snapshot = getEpochSnapshot[currentEpoch()];
        uint256[] memory validatorIDs = snapshot.validatorIDs;

        _sealEpoch_offline(snapshot, validatorIDs, offlineTime, offlineBlocks);
        _sealEpoch_rewards(snapshot, validatorIDs, uptimes, originatedTxsFee);

        currentSealedEpoch = currentEpoch();
        snapshot.endTime = _now();
        snapshot.baseRewardPerSecond = baseRewardPerSecond;
        snapshot.totalSupply = totalSupply;
    }

    /**
     * @dev Sealing the epoch info for validators
     * @param nextValidatorIDs Validator IDs
     */
    function sealEpochValidators(uint256[] calldata nextValidatorIDs)
        external
        onlyDriver
    {
        // fill data for the next snapshot
        EpochSnapshot storage snapshot = getEpochSnapshot[currentEpoch()];
        for (uint256 i = 0; i < nextValidatorIDs.length; i++) {
            uint256 validatorID = nextValidatorIDs[i];
            uint256 receivedStake = getValidator[validatorID].receivedStake;
            snapshot.receivedStake[validatorID] = receivedStake;
            snapshot.totalStake = snapshot.totalStake.add(receivedStake);
        }
        snapshot.validatorIDs = nextValidatorIDs;
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function epochEndTime(uint256 epoch) internal view returns (uint256) {
        return getEpochSnapshot[epoch].endTime;
    }

    /**
     * @dev Is the stake locked up
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     * @return Is the stake locked up
     */
    function isLockedUp(address delegator, uint256 toValidatorID)
        public
        view
        returns (bool)
    {
        return
            getLockupInfo[delegator][toValidatorID].endTime != 0 &&
            getLockupInfo[delegator][toValidatorID].lockedStake != 0 &&
            _now() <= getLockupInfo[delegator][toValidatorID].endTime;
    }

    function _isLockedUpAtEpoch(
        address delegator,
        uint256 toValidatorID,
        uint256 epoch
    ) internal view returns (bool) {
        return
            getLockupInfo[delegator][toValidatorID].fromEpoch <= epoch &&
            epochEndTime(epoch) <=
            getLockupInfo[delegator][toValidatorID].endTime;
    }

    /**
     * @dev Getting the unlocked stake amount
     * @param delegator Delegator address
     * @param toValidatorID Validator ID
     */
    function getUnlockedStake(address delegator, uint256 toValidatorID)
        public
        view
        returns (uint256)
    {
        if (!isLockedUp(delegator, toValidatorID)) {
            return getStake[delegator][toValidatorID];
        }
        return
            getStake[delegator][toValidatorID].sub(
                getLockupInfo[delegator][toValidatorID].lockedStake
            );
    }

    function _lockStake(
        address delegator,
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) internal {
        require(
            amount <= getUnlockedStake(delegator, toValidatorID),
            "not enough stake"
        );
        require(
            getValidator[toValidatorID].status == OK_STATUS,
            "validator isn't active"
        );

        require(
            lockupDuration >= minLockupDuration() &&
                lockupDuration <= maxLockupDuration(),
            "incorrect duration"
        );
        uint256 endTime = _now().add(lockupDuration);
        address validatorAddr = getValidator[toValidatorID].auth;
        if (delegator != validatorAddr) {
            require(
                getLockupInfo[validatorAddr][toValidatorID].endTime >= endTime,
                "validator lockup period will end earlier"
            );
        }

        _stashRewards(delegator, toValidatorID);

        // check lockup duration after _stashRewards, which has erased previous lockup if it has unlocked already
        LockedDelegation storage ld = getLockupInfo[delegator][toValidatorID];
        require(
            lockupDuration >= ld.duration,
            "lockup duration cannot decrease"
        );

        ld.lockedStake = ld.lockedStake.add(amount);
        ld.fromEpoch = currentEpoch();
        ld.endTime = endTime;
        ld.duration = lockupDuration;

        emit LockedUpStake(delegator, toValidatorID, lockupDuration, amount);
    }

    function lockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external {
        address delegator = msg.sender;
        require(amount > 0, "zero amount");
        require(!isLockedUp(delegator, toValidatorID), "already locked up");
        _lockStake(delegator, toValidatorID, lockupDuration, amount);
    }

    function relockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external {
        address delegator = msg.sender;
        _lockStake(delegator, toValidatorID, lockupDuration, amount);
    }

    function _popDelegationUnlockPenalty(
        address delegator,
        uint256 toValidatorID,
        uint256 unlockAmount,
        uint256 totalAmount
    ) internal returns (uint256) {
        uint256 lockupExtraRewardShare = getStashedLockupRewards[delegator][
            toValidatorID
        ].lockupExtraReward.mul(unlockAmount).div(totalAmount);
        uint256 lockupBaseRewardShare = getStashedLockupRewards[delegator][
            toValidatorID
        ].lockupBaseReward.mul(unlockAmount).div(totalAmount);
        uint256 penalty = lockupExtraRewardShare + lockupBaseRewardShare / 2;
        getStashedLockupRewards[delegator][toValidatorID]
            .lockupExtraReward = getStashedLockupRewards[delegator][
            toValidatorID
        ].lockupExtraReward.sub(lockupExtraRewardShare);
        getStashedLockupRewards[delegator][toValidatorID]
            .lockupBaseReward = getStashedLockupRewards[delegator][
            toValidatorID
        ].lockupBaseReward.sub(lockupBaseRewardShare);
        if (penalty >= unlockAmount) {
            penalty = unlockAmount;
        }
        return penalty;
    }

    function unlockStake(uint256 toValidatorID, uint256 amount)
        external
        returns (uint256)
    {
        address delegator = msg.sender;
        LockedDelegation storage ld = getLockupInfo[delegator][toValidatorID];

        require(amount > 0, "zero amount");
        require(isLockedUp(delegator, toValidatorID), "not locked up");
        require(amount <= ld.lockedStake, "not enough locked stake");

        _stashRewards(delegator, toValidatorID);

        uint256 penalty = _popDelegationUnlockPenalty(
            delegator,
            toValidatorID,
            amount,
            ld.lockedStake
        );

        ld.lockedStake -= amount;
        if (penalty != 0) {
            totalPenalty = totalPenalty.add(penalty);
            _rawUndelegate(delegator, toValidatorID, penalty);
        }

        emit UnlockedStake(delegator, toValidatorID, amount, penalty);
        return penalty;
    }
}
