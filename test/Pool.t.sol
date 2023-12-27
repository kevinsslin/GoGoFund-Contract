// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./BaseTest.t.sol";
import { Pool } from "../src/Pool.sol";

contract PoolTest is BaseTest {
    Pool public pool;

    // function setUp() public override {
    //     super.setUp();

    //     changePrank(EVENT_HOLDER);
    //     (address poolAddress) =
    //         poolFactory.createPool(address(usdt), block.timestamp + 1 days, block.timestamp + 31 days, 100_000e18);
    //     pool = Pool(poolAddress);

    //     // let donater as the default msg.sender
    //     changePrank(DONATER);
    //     usdt.approve(address(pool), type(uint256).max);
    // }

    // function test_IsPoolOpen() external {
    //     assertEq(pool.isPoolOpen(), false);

    //     vm.warp(block.timestamp + 1 days);
    //     assertEq(pool.isPoolOpen(), true);
    // }

    // function test_Deposit_RevertWhen_PoolNotOpen() external {
    //     vm.expectRevert(bytes("Pool: pool not open"));
    //     pool.deposit(100e18);

    //     vm.warp(block.timestamp + 31 days + 1);
    //     vm.expectRevert(bytes("Pool: pool not open"));
    //     pool.deposit(100e18);
    // }

    // function test_Deposit() external {
    //     vm.warp(block.timestamp + 1 days);
    //     pool.deposit(100e18);
    //     assertEq(usdt.balanceOf(address(pool)), 100e18);
    //     assertEq(usdt.balanceOf(DONATER), 999_900e18);

    //     assertEq(pool.userDepositInfo(DONATER), 100e18);
    // }

    // function test_Withdraw_RevertWhen_NotAdmin() external {
    //     vm.expectRevert(bytes("Pool: only admin"));
    //     pool.withdraw();
    // }

    // function test_Withdraw_RevertWhen_PoolNotClosed() external {
    //     vm.warp(block.timestamp + 1 days);
    //     pool.deposit(100_000e18);
    //     changePrank(EVENT_HOLDER);
    //     vm.expectRevert(bytes("Pool: pool not closed"));
    //     pool.withdraw();
    // }

    // function test_Withdraw_RevertWhen_TargetNotReached() external {
    //     vm.warp(block.timestamp + 31 days + 1);
    //     changePrank(EVENT_HOLDER);
    //     vm.expectRevert(bytes("Pool: target not reached"));
    //     pool.withdraw();
    // }

    // function test_Withdraw() external {
    //     vm.warp(block.timestamp + 1 days);
    //     pool.deposit(500_000e18);

    //     vm.warp(block.timestamp + 30 days + 1);
    //     changePrank(EVENT_HOLDER);
    //     pool.withdraw();

    //     assertEq(usdt.balanceOf(address(pool)), 0);
    //     assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18 + 500_000e18);
    // }
}
