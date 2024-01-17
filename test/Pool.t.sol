// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Solarray } from "@solarray/Solarray.sol";

import { IPoolEvent } from "../src/interfaces/events/IPoolEvent.sol";
import { Pool } from "../src/Pool.sol";

import "./BaseTest.t.sol";

contract PoolTest is BaseTest, IPoolEvent {
    Pool public pool;

    function setUp() public override {
        super.setUp();

        pool = createDefaultPool();
    }

    function test_mintBatch() external {
        _donatorApproveToPool();

        vm.expectEmit(true, false, true, true);
        emit MintBatch(DONATER, Solarray.uint256s(0, 1, 2), Solarray.uint256s(100, 200, 300));

        pool.mintBatch(DONATER, Solarray.uint256s(0, 1, 2), Solarray.uint256s(100, 200, 300));

        uint256 totalTransferAmount = 100e18 * 100 + 200e18 * 200 + 300e18 * 300;

        assertEq(usdt.balanceOf(address(pool)), totalTransferAmount);
        assertEq(usdt.balanceOf(DONATER), 1_000_000e18 - totalTransferAmount);
        assertEq(pool.userDepositAmounts(DONATER), totalTransferAmount);
        assertEq(pool.balanceOf(DONATER, 0), 100);
        assertEq(pool.balanceOf(DONATER, 1), 200);
        assertEq(pool.balanceOf(DONATER, 2), 300);
    }

    function test_IsPoolOpen() external {
        assertEq(pool.isPoolOpen(), false);

        vm.warp(nowTimestamp + 1 days);
        assertEq(pool.isPoolOpen(), true);

        vm.warp(nowTimestamp + 31 days + 1);
        assertEq(pool.isPoolOpen(), false);
    }

    function test_issuerWithdraw_RevertWhen_NotIssuer() external {
        changePrank(DONATER);
        vm.expectRevert(bytes("Pool: only issuer"));
        pool.issuerWithdraw();
    }

    function test_issuerWithdraw_RevertWhen_PoolUnderVoting() external {
        _donatorApproveToPool();
        _mintBatchDefault();

        changePrank(POOL_ISSUER);
        vm.expectRevert(bytes("Pool: still under voting"));
        pool.issuerWithdraw();
    }

    function test_issuerWithdraw_RevertWhen_TargetNotReached() external {
        vm.warp(block.timestamp + 38 days + 1);
        changePrank(POOL_ISSUER);
        vm.expectRevert(bytes("Pool: target not reached"));
        pool.issuerWithdraw();
    }

    function test_issuerWithdraw() external {
        _donatorApproveToPool();
        _mintBatchDefault();
        uint256 totalTransferAmount = _mintBatchDefault();

        vm.warp(block.timestamp + 38 days + 1);
        changePrank(POOL_ISSUER);
        pool.issuerWithdraw();

        assertEq(usdt.balanceOf(address(pool)), 0);
        assertEq(usdt.balanceOf(POOL_ISSUER), 1_000_000e18 + totalTransferAmount * 2 * ((1e18 - poolFactory.protocolFeeRate())) / 1e18);
    }

    function test_getFundingRatio() external {
        assertEq(pool.getFundingRatio(), 0);

        _donatorApproveToPool();
        _mintBatchDefault();
        assertEq(pool.getFundingRatio(), 7000);
    }

    function _donatorApproveToPool() internal {
        changePrank(DONATER);
        usdt.approve(address(pool), type(uint256).max);
        vm.warp(nowTimestamp + 1 days); // warp to pool open time
    }

    function _mintBatchDefault() internal returns (uint256 totalTransferAmount) {
        pool.mintBatch(DONATER, Solarray.uint256s(0, 1, 2), Solarray.uint256s(100, 200, 300));
        totalTransferAmount = 100e18 * 100 + 200e18 * 200 + 300e18 * 300;
    }
}
