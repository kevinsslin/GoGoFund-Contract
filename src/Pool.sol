// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { IPool } from "./interfaces/IPool.sol";

contract Pool is ERC1155, IPool {
    IERC20 public fundAsset;
    address public issuer;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public targetAmount;
    uint256 public totalDeposit;
    bool public isTargetReached;

    string[] public names;
    uint256[] public ids;
    uint256[] public mintPrices;
    uint256[] public maxSupplys;

    mapping(uint256 => uint256) public totalSupplys;
    mapping(address => uint256) public userDepositInfo;

    mapping(uint256 => uint256) internal _idToPrice;
    mapping(uint256 => uint256) internal _idToMaxSupply;

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Pool: only issuer");
        _;
    }

    modifier onlyPoolOpen() {
        require(_isPoolOpen(), "Pool: pool not open");
        _;
    }

    constructor(
        address fundAsset_,
        address issuer_,
        string memory baseURI_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 targetAmount_,
        string[] memory names_,
        uint256[] memory ids_,
        uint256[] memory mintPrices_,
        uint256[] memory maxSupplys_
    )
        ERC1155(baseURI_)
    {
        require(fundAsset_ != address(0), "Pool: fund asset is zero address");
        require(issuer_ != address(0), "Pool: issuer is zero address");
        require(startTimestamp_ > block.timestamp, "Pool: start timestamp must be in the future");
        require(endTimestamp_ > startTimestamp_, "Pool: end timestamp must be after start timestamp");
        require(targetAmount_ > 0, "Pool: target amount must be greater than zero");

        fundAsset = IERC20(fundAsset_);
        issuer = issuer_;
        names = names_;
        ids = ids_;
        mintPrices = mintPrices_;
        maxSupplys = maxSupplys_;
        _createMapping();
        _setURI(baseURI_);
        startTimestamp = startTimestamp_;
        endTimestamp = endTimestamp_;
        targetAmount = targetAmount_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev mint NFTs to the specified address.
    /// @param to_ the address to mint NFTs to.
    /// @param id_ the id of the NFT to mint.
    /// @param amount_ the amount of NFTs to mint.
    /// @return true if the minting was successful.
    function mint(address to_, uint256 id_, uint256 amount_) external override onlyPoolOpen returns (bool) {
        require(to_ != address(0), "Pool: to is zero address");
        require(amount_ > 0, "Pool: amount must be greater than zero");
        require(totalSupplys[id_] + amount_ <= _idToMaxSupply[id_], "Pool: max supply reached");

        uint256 transferAmount = _idToPrice[id_] * amount_;

        require(
            fundAsset.transferFrom(msg.sender, address(this), transferAmount), "Pool: failed to transfer fund asset"
        );

        _mint(to_, id_, amount_, "");
        emit Mint(to_, id_, amount_);

        userDepositInfo[msg.sender] += transferAmount;
        totalSupplys[id_] += amount_;
        totalDeposit += transferAmount;

        if (fundAsset.balanceOf(address(this)) >= targetAmount) {
            isTargetReached = true;
        }
        return true;
    }

    /// @dev mint NFTs to the specified address.
    /// @param to_ the address to mint NFTs to.
    /// @param ids_ the ids of the NFTs to mint.
    /// @param amounts_ the amounts of NFTs to mint.
    /// @return true if the minting was successful.
    function mintBatch(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyPoolOpen
        returns (bool)
    {
        require(to_ != address(0), "Pool: to is zero address");
        require(ids_.length == amounts_.length, "Pool: ids and amounts length mismatch");

        uint256 totalTransferAmount = 0;
        for (uint256 i = 0; i < ids_.length; ++i) {
            require(amounts_[i] > 0, "Pool: amount must be greater than zero");
            require(totalSupplys[ids_[i]] + amounts_[i] <= _idToMaxSupply[ids_[i]], "Pool: max supply reached");

            totalTransferAmount += _idToPrice[ids_[i]] * amounts_[i];
            totalSupplys[ids_[i]] += amounts_[i];
        }

        require(
            fundAsset.transferFrom(msg.sender, address(this), totalTransferAmount),
            "Pool: failed to transfer fund asset"
        );

        _mintBatch(to_, ids_, amounts_, "");
        emit MintBatch(to_, ids_, amounts_);

        userDepositInfo[msg.sender] += totalTransferAmount;
        totalDeposit += totalTransferAmount;

        if (fundAsset.balanceOf(address(this)) >= targetAmount) {
            isTargetReached = true;
        }
        return true;
    }

    /// @dev withdraw the fund asset from the pool.
    /// @notice this function can only be called by the issuer.
    function withdraw() external override onlyIssuer {
        require(block.timestamp > endTimestamp, "Pool: pool not closed");
        require(isTargetReached == true, "Pool: target not reached");

        uint256 amount = fundAsset.balanceOf(address(this));
        require(amount > 0, "Pool: no fund asset to withdraw");

        require(fundAsset.transfer(issuer, amount), "Pool: failed to transfer fund asset");
        emit Withdraw(issuer, amount);
    }

    /// @dev refund the fund asset to the donators if the target is not reached.
    function refund() external override {
        require((block.timestamp > endTimestamp) == true, "Pool: pool not closed");
        require(isTargetReached == false, "Pool: target reached");

        require(userDepositInfo[msg.sender] > 0, "Pool: no deposit found");

        uint256 amount = userDepositInfo[msg.sender];
        userDepositInfo[msg.sender] = 0;

        require(fundAsset.transfer(msg.sender, amount), "Pool: failed to transfer fund asset");
        emit Refund(msg.sender, amount);
    }

    /// @dev donator burn the NFTs to redeem the real world asset.
    /// @param id_ the id of the NFT to redeem.
    /// @param amount_ the amount of NFTs to redeem.
    function redeem(uint256 id_, uint256 amount_) external override {
        require((block.timestamp > endTimestamp) == true, "Pool: pool not closed");
        require(isTargetReached == true, "Pool: target not reached");
        require(amount_ > 0, "Pool: amount must be greater than zero");
        require(balanceOf(msg.sender, id_) >= amount_, "Pool: insufficient balance");

        _burn(msg.sender, id_, amount_);
        emit Redeem(msg.sender, id_, amount_);
    }

    /// @dev set the issuer of the pool.
    /// @param newIssuer_ the new issuer of the pool.
    /// @notice this function can only be called by the issuer.
    function setIssuer(address newIssuer_) external override onlyIssuer {
        require(newIssuer_ != address(0), "Pool: issuer is zero address");
        emit IssuerChanged(issuer, newIssuer_);
        issuer = newIssuer_;
    }

    /// @dev set start timestamp of the pool.
    /// @param newStartTimestamp_ the new start timestamp of the pool.
    /// @notice this function can only be called by the issuer.
    function setStartTimestamp(uint256 newStartTimestamp_) external override onlyIssuer {
        require(newStartTimestamp_ > block.timestamp, "Pool: start timestamp must be in the future");
        require(newStartTimestamp_ < endTimestamp, "Pool: start timestamp must be before end timestamp");
        emit StartTimestampChanged(startTimestamp, newStartTimestamp_);
        startTimestamp = newStartTimestamp_;
    }

    /// @dev set end timestamp of the pool.
    /// @param newEndTimestamp_ the new end timestamp of the pool.
    /// @notice this function can only be called by the issuer.
    function setEndTimestamp(uint256 newEndTimestamp_) external override onlyIssuer {
        require(newEndTimestamp_ > startTimestamp, "Pool: end timestamp must be after start timestamp");
        require(newEndTimestamp_ > block.timestamp, "Pool: end timestamp must be in the future");
        emit EndTimestampChanged(endTimestamp, newEndTimestamp_);
        endTimestamp = newEndTimestamp_;
    }

    /// @dev set target amount of the pool.
    /// @param newTargetAmount_ the new target amount of the pool.
    /// @notice this function can only be called by the issuer.
    function setTargetAmount(uint256 newTargetAmount_) external override onlyIssuer {
        require(!_isPoolOpen(), "Pool: pool is open");
        require(newTargetAmount_ > 0, "Pool: target amount must be greater than zero");
        emit TargetAmountChanged(targetAmount, newTargetAmount_);
        targetAmount = newTargetAmount_;
    }

    /// @dev set the base URI of the ERC1155 token.
    /// @param _newURI the new base URI of the ERC1155 token.
    /// @notice this function can only be called by the issuer.
    function setURI(string memory _newURI) public onlyIssuer {
        _setURI(_newURI);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function uri(uint256 id_) public view override returns (string memory uri_) {
        return string(abi.encodePacked(super.uri(id_), Strings.toString(id_), ".json"));
    }

    function getFundingRatio() external view override returns (uint256 fundingRatio_) {
        return ud(fundAsset.balanceOf(address(this))).div(ud(targetAmount)).intoUint256() / 1e14;
    }

    function isPoolOpen() external view override returns (bool isOpen_) {
        return _isPoolOpen();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function _isPoolOpen() internal view returns (bool isOpen_) {
        return block.timestamp >= startTimestamp && block.timestamp <= endTimestamp;
    }

    function _createMapping() internal {
        for (uint256 i = 0; i < ids.length; ++i) {
            _idToPrice[ids[i]] = mintPrices[i];
            _idToMaxSupply[ids[i]] = maxSupplys[i];
        }
    }
}
