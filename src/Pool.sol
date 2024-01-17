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
    uint256 public votingEndTimestamp;
    uint256 public targetAmount;
    uint256 public totalDeposit;
    bool public isTargetReached;

    string[] public names;
    uint256[] public ids;
    uint256[] public mintPrices;
    uint256[] public maxSupplys;

    mapping(uint256 => uint256) public totalSupplys;
    mapping(address => uint256) public userDepositAmounts;

    bool public firstPhaseOpposed;
    bool public secondPhaseOpposed;
    uint256 public firstPhaseOppose;
    uint256 public secondPhaseOppose;
    mapping(address => mapping(uint8 => bool)) public voted;

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
        uint256 votingEndTimestamp_,
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
        require(votingEndTimestamp_ > endTimestamp_, "Pool: voting end timestamp must be after end timestamp");
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
        votingEndTimestamp = votingEndTimestamp_;
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

        userDepositAmounts[msg.sender] += transferAmount;
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

        userDepositAmounts[msg.sender] += totalTransferAmount;
        totalDeposit += totalTransferAmount;

        if (fundAsset.balanceOf(address(this)) >= targetAmount) {
            isTargetReached = true;
        }
        return true;
    }

    // TODO: protocol revenue
    /// @dev withdraw the fund asset from the pool if the pool is closed and the target is reached.
    /// @notice this function can only be called by the issuer.
    function issuerWithdraw() external override onlyIssuer {
        require(block.timestamp > votingEndTimestamp, "Pool: still under voting");
        require(isTargetReached == true, "Pool: target not reached");

        uint256 withdrawAmount;
        if (firstPhaseOpposed) {
            withdrawAmount = 0;
        } else if (!firstPhaseOpposed && secondPhaseOpposed) {
            withdrawAmount = fundAsset.balanceOf(address(this)) / 2;
        } else {
            withdrawAmount = fundAsset.balanceOf(address(this));
        }
        require(withdrawAmount > 0, "Pool: no fund asset to withdraw");
        require(fundAsset.transfer(issuer, withdrawAmount), "Pool: failed to transfer fund asset");
        emit IssuerWithdrawal(issuer, withdrawAmount);
    }

    /// @dev burn the NFTs to refund the fund asset to the donators if the target is not reached.
    /// @param ids_ the ids of the NFTs to refund.
    /// @param amounts_ the amounts of NFTs to refund.
    function refundBatch(uint256[] memory ids_, uint256[] memory amounts_) external override {
        require(block.timestamp > endTimestamp, "Pool: pool not closed");
        require(!isTargetReached, "Pool: target reached");

        require(ids_.length == amounts_.length, "Pool: ids and amounts length mismatch");

        uint256 totalRefundAmount = 0;
        for (uint256 i = 0; i < ids_.length; ++i) {
            require(amounts_[i] > 0, "Pool: amount must be greater than zero");
            require(balanceOf(msg.sender, ids_[i]) >= amounts_[i], "Pool: insufficient balance");

            totalRefundAmount += _idToPrice[ids_[i]] * amounts_[i];
        }
        _burnBatch(msg.sender, ids_, amounts_);

        require(userDepositAmounts[msg.sender] >= totalRefundAmount, "Pool: insufficient deposit amount");
        userDepositAmounts[msg.sender] -= totalRefundAmount;

        require(fundAsset.transfer(msg.sender, totalRefundAmount), "Pool: failed to transfer fund asset");
        emit RefundBatch(msg.sender, ids_, amounts_);
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

    /// @dev allow a user to vote in the pool and record their opposition or support for a specific phase.
    /// @param phase_ the phase in which the user is voting.
    /// @param opposed_ whether the user supports (false) or opposes (true) the phase.
    /// @notice this function can only be called by users who have NFTs and have not voted in the phase before.
    function vote(uint8 phase_, bool opposed_) external {
        require(phase_ == 1 || phase_ == 2, "Pool: invalid phase");
        require(!voted[msg.sender][phase_], "Pool: already voted");
        require(block.timestamp < votingEndTimestamp, "Pool: voting ended");

        // check if user is eligible to vote by checking if user has any NFTs
        for (uint256 i = 0; i < ids.length; ++i) {
            if (balanceOf(msg.sender, ids[i]) > 0) {
                break;
            }
            require(i != ids.length - 1, "Pool: user has no NFTs");
        }

        voted[msg.sender][phase_] = true;

        // Update the phase support based on the user's deposit amount and check if the phase threshold is reached
        if (opposed_) {
            // If user votes to oppose
            if (phase_ == 1) {
                firstPhaseOppose += userDepositAmounts[msg.sender];
                if (firstPhaseOppose >= fundAsset.balanceOf(address(this)) / 2) {
                    firstPhaseOpposed = true;
                }
            } else {
                secondPhaseOppose += userDepositAmounts[msg.sender];
                if (secondPhaseOppose >= fundAsset.balanceOf(address(this)) / 2) {
                    secondPhaseOpposed = true;
                }
            }
        }

        emit Vote(msg.sender, phase_, opposed_);
    }

    /// @dev allow a donator to withdraw their funds based on the voting results of the phases.
    /// @notice this function can only be called after the pool is closed and the target is not reached.
    function donatorWithdraw() external override {
        require(block.timestamp > votingEndTimestamp, "Pool: still under voting");
        require(isTargetReached, "Pool: target not reach");
        require(userDepositAmounts[msg.sender] > 0, "Pool: no deposit to withdraw");
        require(firstPhaseOpposed || secondPhaseOpposed, "Pool: phases not opposed, cannot withdraw");

        uint256 withdrawAmount = userDepositAmounts[msg.sender];

        // If the first phase is opposed, the donator can withdraw all their funds.
        // If the first phase is not opposed but the second phase is, they can withdraw half of their funds.
        if (firstPhaseOpposed) {
            // Allow withdrawing all funds
        } else if (secondPhaseOpposed) {
            // Allow withdrawing half of the funds
            withdrawAmount = withdrawAmount / 2;
        }

        userDepositAmounts[msg.sender] = 0;
        require(fundAsset.transfer(msg.sender, withdrawAmount), "Pool: failed to transfer fund asset");
        emit DonatorWithdrawal(msg.sender, withdrawAmount);
    }

    /// @dev set voting end timestamp of the pool.
    /// @param newVotingEndTimestamp_ the new voting end timestamp of the pool.
    /// @notice this function can only be called by the issuer.
    function setVotingEndTimestamp(uint256 newVotingEndTimestamp_) external override onlyIssuer {
        require(newVotingEndTimestamp_ > endTimestamp, "Pool: voting end timestamp must be after end timestamp");
        require(newVotingEndTimestamp_ > block.timestamp, "Pool: voting end timestamp must be in the future");
        emit VotingEndTimestampChanged(votingEndTimestamp, newVotingEndTimestamp_);
        votingEndTimestamp = newVotingEndTimestamp_;
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
