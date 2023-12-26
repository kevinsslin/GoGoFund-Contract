// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPoolFactory {
    event PoolCreated(address indexed issuer_, address indexed pool_);

    function createPool(
        address fundAsset_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 targetAmount_
    )
        external
        returns (address pool_);
}
