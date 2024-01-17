// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Pool } from "./Pool.sol";
import { IPoolFactory } from "./interfaces/IPoolFactory.sol";

contract PoolFactory is IPoolFactory, Ownable {
    constructor() Ownable(msg.sender) { }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function createPool(
        address fundAsset_,
        string memory baseURI_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 votingEndTimestamp_,
        uint256 targetAmount_,
        string[] memory names_,
        uint256[] memory ids_,
        uint256[] memory mintPrices_,
        uint256[] memory maxSupplys_
    )
        external
        override
        returns (address pool_)
    {
        Pool pool = new Pool(
            fundAsset_,
            msg.sender,
            baseURI_,
            startTimestamp_,
            endTimestamp_,
            votingEndTimestamp_,
            targetAmount_,
            names_,
            ids_,
            mintPrices_,
            maxSupplys_
        );
        emit PoolCreated(msg.sender, address(pool));
        return (address(pool));
    }
}
