// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Pool as P } from "./libraries/DataTypes.sol";

import { Pool } from "./Pool.sol";
import { IPoolFactory } from "./interfaces/IPoolFactory.sol";

contract PoolFactory is IPoolFactory, Ownable {
    uint256 public protocolFeeRate = 0.01e18; // 1%

    constructor() Ownable(msg.sender) { }

    // TODO: add withdraw by owner

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createPool(P.Configs memory configs) external override returns (address pool_) {
        Pool pool = new Pool(address(this), configs);
        emit PoolCreated(msg.sender, address(pool));
        return (address(pool));
    }
}
