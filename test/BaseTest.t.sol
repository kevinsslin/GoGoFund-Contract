// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { StdCheats } from "forge-std/StdCheats.sol";
import { console } from "forge-std/console.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { PoolFactory } from "../src/PoolFactory.sol";
import { MockERC20 } from "./utils/MockERC20.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    MockERC20 internal usdt;

    PoolFactory public poolFactory;

    address payable EVENT_HOLDER;
    address payable DONATER;

    function setUp() public virtual {
        usdt = new MockERC20("USDT Stablecoin", "USDT");

        // create all the users
        EVENT_HOLDER = createUser("EVENT_HOLDER");
        DONATER = createUser("DONATER");

        // deploy the funding pool factory
        poolFactory = new PoolFactory();

        // label the base test contract
        vm.label(address(usdt), "USDT");

        // set event holder as the default msg.sender
        vm.startPrank(EVENT_HOLDER);
    }

    function test_setUpState() public {
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18);
        assertEq(usdt.balanceOf(DONATER), 1_000_000e18);
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }
}
