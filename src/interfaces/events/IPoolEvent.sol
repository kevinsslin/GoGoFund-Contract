// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IPoolEvent {
    event Mint(address indexed to_, uint256 indexed id_, uint256 indexed amount_);

    event MintBatch(address indexed to_, uint256[] indexed ids_, uint256[] indexed amounts_);

    event Withdraw(address indexed issuer_, uint256 amount_);

    event Refund(address indexed user_, uint256 indexed amount_);

    event Redeem(address indexed user_, uint256 indexed id_, uint256 indexed amount_);

    event IssuerChanged(address indexed oldIssuer_, address indexed newIssuer_);

    event FundAssetChanged(address indexed oldFundAsset_, address indexed newFundAsset_);

    event StartTimestampChanged(uint256 indexed oldStartTimestamp_, uint256 indexed newStartTimestamp_);

    event EndTimestampChanged(uint256 indexed oldEndTimestamp_, uint256 indexed newEndTimestamp_);

    event TargetAmountChanged(uint256 indexed oldTargetAmount_, uint256 indexed newTargetAmount_);
}
