// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Solarray } from "@solarray/Solarray.sol";

import { Pool as P } from "../src/libraries/DataTypes.sol";

import { IPoolFactoryEvent } from "../src/interfaces/events/IPoolFactoryEvent.sol";
import { Pool } from "../src/Pool.sol";

import "./BaseTest.t.sol";

contract PoolFactoryTest is BaseTest, IPoolFactoryEvent {
    function setUp() public override {
        super.setUp();
    }

    function test_createPool() external {
        P.Configs memory configs = P.Configs({
            fundAsset: address(usdt),
            issuer: POOL_ISSUER,
            baseURI: "https:test.com/",
            startTimestamp: nowTimestamp + 1 days,
            endTimestamp: nowTimestamp + 31 days,
            votingEndTimestamp: nowTimestamp + 38 days,
            targetAmount: 200_000e18,
            names: Solarray.strings("test1", "test2", "test3"),
            ids: Solarray.uint256s(0, 1, 2),
            mintPrices: Solarray.uint256s(100e18, 200e18, 300e18),
            maxSupplys: Solarray.uint256s(1000, 2000, 3000)
        });

        vm.expectEmit(true, false, true, true);
        emit PoolCreated(POOL_ISSUER, address(0));

        address poolAddress = poolFactory.createPool(configs);

        Pool pool = Pool(poolAddress);
        assertEq(address(pool.fundAsset()), address(usdt));
        assertEq(pool.uri(0), "https:test.com/0.json");
        assertEq(pool.startTimestamp(), nowTimestamp + 1 days);
        assertEq(pool.endTimestamp(), nowTimestamp + 31 days);
        assertEq(pool.votingEndTimestamp(), nowTimestamp + 38 days);
        assertEq(pool.targetAmount(), 200_000e18);
    }
}
