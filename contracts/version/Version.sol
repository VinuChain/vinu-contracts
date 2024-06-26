pragma solidity 0.5.17;

/**
 * @dev Version contract gives the versioning information of the implementation contract
 */
contract Version {
    /**
     * @dev Returns the address of the current owner.
     */
    function version() external pure returns (bytes3) {
        // version 3.0.4
        return "304";
    }
}
