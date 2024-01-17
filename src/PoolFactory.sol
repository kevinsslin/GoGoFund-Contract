// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Pool as P } from "./libraries/DataTypes.sol";

import { Pool } from "./Pool.sol";
import { IPoolFactory } from "./interfaces/IPoolFactory.sol";

/// @title PoolFactory
/// @dev Contract for creating and managing pools
contract PoolFactory is IPoolFactory, Ownable {
    uint256 public protocolFeeRate = 0.01e18; // 1%

    constructor() Ownable(msg.sender) { }

    /// @dev Withdraws the entire balance of the specified fund asset to the owner
    /// @param fundAsset_ Address of the fund asset
    function withdraw(address fundAsset_) external onlyOwner {
        uint256 balance = IERC20(fundAsset_).balanceOf(address(this));
        IERC20(fundAsset_).transfer(msg.sender, balance);
    }

    /// @dev Sets the protocol fee rate
    /// @param protocolFeeRate_ New protocol fee rate
    function setProtocolFeeRate(uint256 protocolFeeRate_) external onlyOwner {
        require(protocolFeeRate_ <= 1e18, "PoolFactory: protocol fee rate must be less than or equal to 100%");
        require(protocolFeeRate_ >= 0, "PoolFactory: protocol fee rate must be greater than or equal to 0%");
        protocolFeeRate = protocolFeeRate_;
        emit ProtocolFeeRateSet(protocolFeeRate_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a new pool with the provided configurations
    /// @param configs Pool configurations
    /// @return pool_ Address of the created pool
    function createPool(P.Configs memory configs) external override returns (address pool_) {
        Pool pool = new Pool(address(this), configs);
        emit PoolCreated(msg.sender, address(pool));
        return (address(pool));
    }
}
