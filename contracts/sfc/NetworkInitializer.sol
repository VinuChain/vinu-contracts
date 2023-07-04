pragma experimental ABIEncoderV2;
pragma solidity 0.5.17;

import "./SFC.sol";
import "./NodeDriver.sol";

/**
 * @title NetworkInitializer
 * @dev Initializer of system contracts
 */
contract NetworkInitializer {
    /**
     * @dev Initialize NodeDriverAuth, NodeDriver and SFC in one call to allow fewer genesis transactions
     * @param sealedEpoch Current sealed epoch
     * @param totalSupply Native token total supply
     * @param _sfc SFC contract address
     * @param _auth NodeDriverAuth contract address
     * @param _driver NodeDriver contract address
     * @param _evmWriter EVMWriter contract address
     * @param _owner Owner
     */
    function initializeAll(
        uint256 sealedEpoch,
        uint256 totalSupply,
        address payable _sfc,
        address _auth,
        address _driver,
        address _evmWriter,
        address _owner
    ) external {
        NodeDriver(_driver).initialize(_auth, _evmWriter);
        NodeDriverAuth(_auth).initialize(_sfc, _driver, _owner);

        SFC(_sfc).initialize(
            sealedEpoch,
            totalSupply,
            _auth,
            _owner
        );
        selfdestruct(address(0));
    }
}
