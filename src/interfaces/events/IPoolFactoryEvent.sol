// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPoolFactoryEvent {
    event PoolCreated(address indexed issuer_, address indexed pool_);
}
