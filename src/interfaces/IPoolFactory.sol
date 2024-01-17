// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Pool as P } from "../libraries/DataTypes.sol";

import { IPoolFactoryEvent } from "./events/IPoolFactoryEvent.sol";

interface IPoolFactory is IPoolFactoryEvent {
    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createPool(P.Configs memory configs_) external returns (address pool_);

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function protocolFeeRate() external view returns (uint256 protocolFeeRate_);
}
