// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IPoolFactoryEvent } from "./events/IPoolFactoryEvent.sol";

interface IPoolFactory is IPoolFactoryEvent {
    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createPool(
        address fundAsset_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 targetAmount_
    )
        external
        returns (address pool_);
}
