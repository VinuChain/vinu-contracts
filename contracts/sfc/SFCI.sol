pragma experimental ABIEncoderV2;
pragma solidity 0.5.17;

interface SFCI {
    struct Stake {
        address delegator;
        uint96 timestamp;
        uint256 validatorId;
        uint256 amount;
    }

    struct WithdrawalRequest {
        uint256 epoch;
        uint256 time;
        uint256 amount;
    }

    function MIN_OFFLINE_PENALTY_THRESHOLD_TIME()
        external
        view
        returns (uint256);

    function MIN_OFFLINE_PENALTY_THRESHOLD_BLOCKS_NUM()
        external
        view
        returns (uint256);

    function currentSealedEpoch() external view returns (uint256);

    function genesisValidator() external view returns (address);

    function getEpochSnapshot(
        uint256
    )
        external
        view
        returns (
            uint256 endTime,
            uint256 epochFee,
            uint256 totalBaseRewardWeight,
            uint256 totalTxRewardWeight,
            uint256 _baseRewardPerSecond,
            uint256 totalStake,
            uint256 totalSupply
        );

    function getLockupInfo(
        address,
        uint256
    )
        external
        view
        returns (
            uint256 lockedStake,
            uint256 fromEpoch,
            uint256 endTime,
            uint256 duration
        );

    function getStake(address, uint256) external view returns (uint256);

    function getStakes(
        uint256 offset,
        uint256 limit
    ) external view returns (Stake[] memory);

    function getWrRequests(
        address delegator,
        uint256 validatorID,
        uint256 offset,
        uint256 limit
    ) external view returns (WithdrawalRequest[] memory);

    function getStashedLockupRewards(
        address,
        uint256
    )
        external
        view
        returns (
            uint256 lockupExtraReward,
            uint256 lockupBaseReward,
            uint256 unlockedReward
        );

    function getValidator(
        uint256
    )
        external
        view
        returns (
            uint256 status,
            uint256 deactivatedTime,
            uint256 deactivatedEpoch,
            uint256 receivedStake,
            uint256 createdEpoch,
            uint256 createdTime,
            address auth
        );

    function getValidatorID(address) external view returns (uint256);

    function getValidatorPubkey(uint256) external view returns (bytes memory);

    function getWithdrawalRequest(
        address,
        uint256,
        uint256
    ) external view returns (uint256 epoch, uint256 time, uint256 amount);

    function isOwner() external view returns (bool);

    function lastValidatorID() external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function slashingRefundRatio(uint256) external view returns (uint256);

    function stashedRewardsUntilEpoch(
        address,
        uint256
    ) external view returns (uint256);

    function totalActiveStake() external view returns (uint256);

    function totalSlashedStake() external view returns (uint256);

    function totalStake() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalPenalty() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function version() external pure returns (bytes3);

    function currentEpoch() external view returns (uint256);

    function getEpochValidatorIDs(
        uint256 epoch
    ) external view returns (uint256[] memory);

    function getEpochReceivedStake(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function getEpochAccumulatedRewardPerToken(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function getEpochAccumulatedUptime(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function getEpochAccumulatedOriginatedTxsFee(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function getEpochOfflineTime(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function getEpochOfflineBlocks(
        uint256 epoch,
        uint256 validatorID
    ) external view returns (uint256);

    function rewardsStash(
        address delegator,
        uint256 validatorID
    ) external view returns (uint256);

    function getLockedStake(
        address delegator,
        uint256 toValidatorID
    ) external view returns (uint256);

    function createValidator(bytes calldata pubkey) external payable;

    function getSelfStake(uint256 validatorID) external view returns (uint256);

    function delegate(uint256 toValidatorID) external payable;

    function undelegate(uint256 toValidatorID, uint256 amount) external;

    function isSlashed(uint256 validatorID) external view returns (bool);

    function withdraw(uint256 toValidatorID, uint256 wrID) external;

    function deactivateValidator(uint256 validatorID, uint256 status) external;

    function pendingRewards(
        address delegator,
        uint256 toValidatorID
    ) external view returns (uint256);

    function stashRewards(address delegator, uint256 toValidatorID) external;

    function claimRewards(uint256 toValidatorID) external;

    function restakeRewards(uint256 toValidatorID) external;

    function updateBaseRewardPerSecond(uint256 value) external;

    function updateOfflinePenaltyThreshold(
        uint256 blocksNum,
        uint256 time
    ) external;

    function updateSlashingRefundRatio(
        uint256 validatorID,
        uint256 refundRatio
    ) external;

    function sealEpoch(
        uint256[] calldata offlineTime,
        uint256[] calldata offlineBlocks,
        uint256[] calldata uptimes,
        uint256[] calldata originatedTxsFee
    ) external;

    function sealEpochValidators(uint256[] calldata nextValidatorIDs) external;

    function isLockedUp(
        address delegator,
        uint256 toValidatorID
    ) external view returns (bool);

    function getUnlockedStake(
        address delegator,
        uint256 toValidatorID
    ) external view returns (uint256);

    function lockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function relockStake(
        uint256 toValidatorID,
        uint256 lockupDuration,
        uint256 amount
    ) external;

    function unlockStake(
        uint256 toValidatorID,
        uint256 amount
    ) external returns (uint256);

    function initialize(
        uint256 sealedEpoch,
        uint256 _totalSupply,
        address nodeDriver,
        address _owner
    ) external;

    function setGenesisValidator(
        address auth,
        uint256 validatorID,
        bytes calldata pubkey,
        uint256 status,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedEpoch,
        uint256 deactivatedTime
    ) external;

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
    ) external;

    function minSelfStake() external pure returns (uint256);

    function maxDelegatedRatio() external pure returns (uint256);

    function validatorCommission() external pure returns (uint256);

    function contractCommission() external pure returns (uint256);

    function unlockedRewardRatio() external pure returns (uint256);

    function minLockupDuration() external pure returns (uint256);

    function maxLockupDuration() external pure returns (uint256);

    function withdrawalPeriodEpochs() external pure returns (uint256);

    function withdrawalPeriodTime() external pure returns (uint256);

    function withdrawalPeriodEpochsValidator() external pure returns (uint256);

    function withdrawalPeriodTimeValidator() external pure returns (uint256);

    function offlinePenaltyThresholdTime() external view returns (uint256);

    function offlinePenaltyThresholdBlocksNum() external view returns (uint256);
}
