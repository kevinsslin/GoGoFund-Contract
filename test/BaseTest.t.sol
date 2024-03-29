// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { StdCheats } from "forge-std/StdCheats.sol";
import { console } from "forge-std/console.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Solarray } from "@solarray/Solarray.sol";

import { MockERC20 } from "./utils/MockERC20.sol";

import { Pool as P } from "../src/libraries/DataTypes.sol";

import { PoolFactory } from "../src/PoolFactory.sol";
import { Pool } from "../src/Pool.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    MockERC20 internal usdt;

    PoolFactory public poolFactory;

    address payable POOL_ISSUER;
    address payable DONATER;

    uint256 nowTimestamp;

    function setUp() public virtual {
        // deploy the test contracts and label them
        usdt = new MockERC20("USDT Stablecoin", "USDT");
        poolFactory = new PoolFactory();

        vm.label(address(usdt), "USDT");
        vm.label(address(poolFactory), "PoolFactory");

        // create all the users
        POOL_ISSUER = createUser("POOL_ISSUER");
        DONATER = createUser("DONATER");

        // set event holder as the default msg.sender
        vm.startPrank(POOL_ISSUER);
        nowTimestamp = block.timestamp;
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }

    function createDefaultPool() internal returns (Pool) {
        P.Configs memory configs = P.Configs({
            fundAsset: address(usdt),
            issuer: POOL_ISSUER,
            baseURI: "https:test.com",
            startTimestamp: nowTimestamp + 1 days,
            endTimestamp: nowTimestamp + 31 days,
            votingEndTimestamp: nowTimestamp + 38 days,
            targetAmount: 200_000e18,
            names: Solarray.strings("test1", "test2", "test3"),
            ids: Solarray.uint256s(0, 1, 2),
            mintPrices: Solarray.uint256s(100e18, 200e18, 300e18),
            maxSupplys: Solarray.uint256s(1000, 2000, 3000)
        });

        address poolAddress = poolFactory.createPool(configs);
        return Pool(poolAddress);
    }
}
