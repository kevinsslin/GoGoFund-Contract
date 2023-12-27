// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IPoolEvent } from "./events/IPoolEvent.sol";

interface IPool is IPoolEvent {
    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function mint(address to_, uint256 id_, uint256 amount_) external returns (bool);

    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);

    function withdraw() external;

    function refund() external;

    function redeem(uint256 id_, uint256 amount_) external;

    function setIssuer(address newIssuer_) external;

    function setStartTimestamp(uint256 newStartTimestamp_) external;

    function setEndTimestamp(uint256 newEndTimestamp_) external;

    function setTargetAmount(uint256 newTargetAmount_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getFundingRatio() external view returns (uint256 fundingRatio_);

    function isPoolOpen() external view returns (bool isOpen_);
}
