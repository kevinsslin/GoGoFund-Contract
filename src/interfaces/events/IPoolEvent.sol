// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPoolEvent {
    event Deposit(address indexed user_, uint256 amount_);

    event Withdraw(address indexed admin_, uint256 amount_);

    event Redeem(address indexed user_, uint256 amount_);

    event AdminChanged(address indexed oldAdmin_, address indexed newAdmin_);

    event FundAssetChanged(address indexed oldFundAsset_, address indexed newFundAsset_);

    event StartTimestampChanged(uint256 indexed oldStartTimestamp_, uint256 indexed newStartTimestamp_);

    event EndTimestampChanged(uint256 indexed oldEndTimestamp_, uint256 indexed newEndTimestamp_);

    event TargetAmountChanged(uint256 indexed oldTargetAmount_, uint256 indexed newTargetAmount_);
}
