// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IPool } from "./interfaces/IPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool is IPool {
    IERC20 public fundAsset;
    address public admin;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public targetAmount;
    uint256 public totalDepositedAmount;
    bool public isTargetReached;

    mapping(address => uint256) public userDepositInfo;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Pool: only admin");
        _;
    }

    modifier WhenOpen() {
        require(_isPoolOpen(), "Pool: pool not open");
        _;
    }

    constructor(
        address fundAsset_,
        address admin_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 targetAmount_
    ) {
        require(fundAsset_ != address(0), "Pool: fund asset is zero address");
        require(admin_ != address(0), "Pool: admin is zero address");
        require(startTimestamp_ > block.timestamp, "Pool: start timestamp must be in the future");
        require(endTimestamp_ > startTimestamp_, "Pool: end timestamp must be after start timestamp");
        require(targetAmount_ > 0, "Pool: target amount must be greater than zero");

        fundAsset = IERC20(fundAsset_);
        admin = admin_;
        startTimestamp = startTimestamp_;
        endTimestamp = endTimestamp_;
        targetAmount = targetAmount_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit `amount_` of `fundAsset` into the pool.
     */
    function deposit(uint256 amount_) external override WhenOpen {
        require(amount_ > 0, "Pool: amount must be greater than zero");
        require(fundAsset.transferFrom(msg.sender, address(this), amount_), "Pool: failed to transfer fund asset");

        userDepositInfo[msg.sender] += amount_;

        emit Deposit(msg.sender, amount_);

        if (fundAsset.balanceOf(address(this)) >= targetAmount) {
            isTargetReached = true;
        }
    }

    /**
     * @dev admin withdraws all fund asset from the pool.
     */
    function withdraw() external override onlyAdmin {
        require(block.timestamp > endTimestamp, "Pool: pool not closed");
        require(isTargetReached == true, "Pool: target not reached");

        uint256 amount = fundAsset.balanceOf(address(this));
        require(amount > 0, "Pool: no fund asset to withdraw");

        require(fundAsset.transfer(admin, amount), "Pool: failed to transfer fund asset");
        emit Withdraw(admin, amount);
    }

    function redeem() external override {
        require((block.timestamp > endTimestamp) == true, "Pool: pool not closed");
        require(isTargetReached == false, "Pool: target reached");

        require(userDepositInfo[msg.sender] > 0, "Pool: no deposit found");

        uint256 amount = userDepositInfo[msg.sender];
        userDepositInfo[msg.sender] = 0;

        require(fundAsset.transfer(msg.sender, amount), "Pool: failed to transfer fund asset");
        emit Redeem(msg.sender, amount);
    }

    function setAdmin(address admin_) external override onlyAdmin {
        require(admin_ != address(0), "Pool: admin is zero address");
        emit AdminChanged(admin, admin_);
        admin = admin_;
    }

    function setFundAsset(address fundAsset_) external override onlyAdmin {
        require(fundAsset_ != address(0), "Pool: fund asset is zero address");
        emit FundAssetChanged(address(fundAsset), fundAsset_);
        fundAsset = IERC20(fundAsset_);
    }

    function setStartTimestamp(uint256 startTimestamp_) external override onlyAdmin {
        require(startTimestamp_ > block.timestamp, "Pool: start timestamp must be in the future");
        require(startTimestamp_ < endTimestamp, "Pool: start timestamp must be before end timestamp");
        emit StartTimestampChanged(startTimestamp, startTimestamp_);
        startTimestamp = startTimestamp_;
    }

    function setEndTimestamp(uint256 endTimestamp_) external override onlyAdmin {
        require(endTimestamp_ > startTimestamp, "Pool: end timestamp must be after start timestamp");
        require(endTimestamp_ > block.timestamp, "Pool: end timestamp must be in the future");
        emit EndTimestampChanged(endTimestamp, endTimestamp_);
        endTimestamp = endTimestamp_;
    }

    function setTargetAmount(uint256 targetAmount_) external override onlyAdmin {
        require(!_isPoolOpen(), "Pool: pool is open");
        require(targetAmount_ > 0, "Pool: target amount must be greater than zero");
        emit TargetAmountChanged(targetAmount, targetAmount_);
        targetAmount = targetAmount_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function isPoolOpen() external view override returns (bool isOpen_) {
        return _isPoolOpen();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function _isPoolOpen() internal view returns (bool isOpen_) {
        return block.timestamp >= startTimestamp && block.timestamp <= endTimestamp;
    }
}
