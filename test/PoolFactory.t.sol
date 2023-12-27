// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Solarray } from "@solarray/Solarray.sol";

import "./BaseTest.t.sol";

contract PoolFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_createPool() external {
        poolFactory.createPool(
            address(usdt),
            "https:test.com",
            nowTimestamp + 1 days,
            nowTimestamp + 31 days,
            100_000e18,
            Solarray.strings("test1", "test2", "test3"),
            Solarray.uint256s(0, 1, 2),
            Solarray.uint256s(100e18, 200e18, 300e18),
            Solarray.uint256s(1000, 2000, 3000)
        );
    }
}
