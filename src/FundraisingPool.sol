// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IFundraisingPool } from "./interfaces/IFundraisingPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FundraisingPool is IFundraisingPool {
    //** Storage */

    IERC20 public fundAsset;
    address public admin;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public targetAmount;
    uint256 public totalDepositedAmount;
    bool public isTargetReached;

    mapping(address => uint256) public userDepositInfo;

    //** Modifiers */

    modifier onlyAdmin() {
        require(msg.sender == admin, "FundraisingPool: only admin");
        _;
    }

    modifier WhenOpen() {
        require(_isPoolOpen(), "FundraisingPool: pool not open");
        _;
    }

    constructor(
        address _fundAsset,
        address _admin,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _targetAmount
    ) {
        require(_fundAsset != address(0), "FundraisingPool: fund asset is zero address");
        require(_admin != address(0), "FundraisingPool: admin is zero address");
        require(_startTimestamp > block.timestamp, "FundraisingPool: start timestamp must be in the future");
        require(_endTimestamp > _startTimestamp, "FundraisingPool: end timestamp must be after start timestamp");
        require(_targetAmount > 0, "FundraisingPool: target amount must be greater than zero");

        fundAsset = IERC20(_fundAsset);
        admin = _admin;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        targetAmount = _targetAmount;
    }

    //** View Functions */

    function isPoolOpen() external view override returns (bool _isOpen) {
        return _isPoolOpen();
    }

    //** External Functions */

    /**
     * @dev Deposit `_amount` of `fundAsset` into the pool.
     */
    function deposit(uint256 _amount) external override WhenOpen {
        require(_amount > 0, "FundraisingPool: amount must be greater than zero");
        require(
            fundAsset.transferFrom(msg.sender, address(this), _amount), "FundraisingPool: failed to transfer fund asset"
        );

        userDepositInfo[msg.sender] += _amount;

        emit Deposit(msg.sender, _amount);

        if (fundAsset.balanceOf(address(this)) >= targetAmount) {
            isTargetReached = true;
        }
    }

    /**
     * @dev admin withdraws all fund asset from the pool.
     */
    function withdraw() external override onlyAdmin {
        require(block.timestamp > endTimestamp, "FundraisingPool: pool not closed");
        require(isTargetReached == true, "FundraisingPool: target not reached");

        uint256 amount = fundAsset.balanceOf(address(this));
        require(amount > 0, "FundraisingPool: no fund asset to withdraw");

        require(fundAsset.transfer(admin, amount), "FundraisingPool: failed to transfer fund asset");
        emit Withdraw(admin, amount);
    }

    function redeem() external override {
        require((block.timestamp > endTimestamp) == true, "FundraisingPool: pool not closed");
        require(isTargetReached == false, "FundraisingPool: target reached");

        require(userDepositInfo[msg.sender] > 0, "FundraisingPool: no deposit found");

        uint256 amount = userDepositInfo[msg.sender];
        userDepositInfo[msg.sender] = 0;

        require(fundAsset.transfer(msg.sender, amount), "FundraisingPool: failed to transfer fund asset");
        emit Redeem(msg.sender, amount);
    }

    function setAdmin(address _admin) external override onlyAdmin {
        require(_admin != address(0), "FundraisingPool: admin is zero address");
        emit AdminChanged(admin, _admin);
        admin = _admin;
    }

    function setFundAsset(address _fundAsset) external override onlyAdmin {
        require(_fundAsset != address(0), "FundraisingPool: fund asset is zero address");
        emit FundAssetChanged(address(fundAsset), _fundAsset);
        fundAsset = IERC20(_fundAsset);
    }

    function setStartTimestamp(uint256 _startTimestamp) external override onlyAdmin {
        require(_startTimestamp > block.timestamp, "FundraisingPool: start timestamp must be in the future");
        require(_startTimestamp < endTimestamp, "FundraisingPool: start timestamp must be before end timestamp");
        emit StartTimestampChanged(startTimestamp, _startTimestamp);
        startTimestamp = _startTimestamp;
    }

    function setEndTimestamp(uint256 _endTimestamp) external override onlyAdmin {
        require(_endTimestamp > startTimestamp, "FundraisingPool: end timestamp must be after start timestamp");
        require(_endTimestamp > block.timestamp, "FundraisingPool: end timestamp must be in the future");
        emit EndTimestampChanged(endTimestamp, _endTimestamp);
        endTimestamp = _endTimestamp;
    }

    function setTargetAmount(uint256 _targetAmount) external override onlyAdmin {
        require(!_isPoolOpen(), "FundraisingPool: pool is open");
        require(_targetAmount > 0, "FundraisingPool: target amount must be greater than zero");
        emit TargetAmountChanged(targetAmount, _targetAmount);
        targetAmount = _targetAmount;
    }

    //** Helper Functions */

    function _isPoolOpen() internal view returns (bool _isOpen) {
        return block.timestamp >= startTimestamp && block.timestamp <= endTimestamp;
    }
}
