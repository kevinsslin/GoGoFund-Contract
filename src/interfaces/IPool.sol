// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IPoolEvent } from "./events/IPoolEvent.sol";

interface IPool is IPoolEvent {
    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount_) external;

    function withdraw() external;

    function redeem() external;

    function setAdmin(address admin_) external;

    function setFundAsset(address fundAsset_) external;

    function setStartTimestamp(uint256 startTimestamp_) external;

    function setEndTimestamp(uint256 endTimestamp_) external;

    function setTargetAmount(uint256 targetAmount_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function isPoolOpen() external view returns (bool isOpen_);
}
