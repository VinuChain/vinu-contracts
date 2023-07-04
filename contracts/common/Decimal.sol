pragma experimental ABIEncoderV2;
pragma solidity 0.5.17;

/**
 * @title Decimal
 * @dev Is used for decimals, e.g. 0.123456
 */
library Decimal {
    function unit() internal pure returns (uint256) {
        return 1e18;
    }
}
