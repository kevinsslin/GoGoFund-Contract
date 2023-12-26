// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { StdCheats } from "forge-std/StdCheats.sol";
import { console } from "forge-std/console.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { UUPSProxy } from "../src/libraries/UUPSProxy.sol";

import { Globals } from "../src/Globals.sol";
import { FundraisingPoolFactory } from "../src/FundraisingPoolFactory.sol";
import { MockERC20 } from "./utils/MockERC20.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    MockERC20 internal usdt;

    Globals public globals;
    FundraisingPoolFactory public fundraisingPoolFactory;

    address payable GOVERNOR;
    address payable EVENT_HOLDER;
    address payable EVENT_PARTICIPANT;
    address payable DONATER;

    function setUp() public virtual {
        usdt = new MockERC20("USDT Stablecoin", "USDT");

        // create all the users
        GOVERNOR = createUser("GOVERNOR");
        EVENT_HOLDER = createUser("EVENT_HOLDER");
        EVENT_PARTICIPANT = createUser("EVENT_PARTICIPANT");
        DONATER = createUser("DONATER");

        // deploy globals and set the governor
        globals = deployAndSetUpGlobals();

        // deploy the ticket factory and set the globals address

        // deploy the funding pool factory and set the globals address
        fundraisingPoolFactory = new FundraisingPoolFactory(address(globals));

        // label the base test contract
        vm.label(address(usdt), "USDT");
        vm.label(address(globals), "Globals");

        // set event holder as the default msg.sender
        vm.startPrank(EVENT_HOLDER);
    }

    function test_setUpState() public {
        assertEq(globals.governor(), GOVERNOR);
        assertEq(usdt.balanceOf(GOVERNOR), 1_000_000e18);
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18);
        assertEq(usdt.balanceOf(EVENT_PARTICIPANT), 1_000_000e18);
        assertEq(usdt.balanceOf(DONATER), 1_000_000e18);
        assertTrue(globals.isValidEventHolder(EVENT_HOLDER));
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }

    function deployAndSetUpGlobals() internal returns (Globals _globals) {
        vm.startPrank(GOVERNOR);
        _globals = Globals(address(new UUPSProxy(address(new Globals()), "")));
        _globals.initialize(GOVERNOR);
        _globals.setValidEventHolder(EVENT_HOLDER, true);
    }
}
