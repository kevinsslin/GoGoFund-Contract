// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

library Pool {
    struct Configs {
        address fundAsset;
        address issuer;
        string baseURI;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votingEndTimestamp;
        uint256 targetAmount;
        string[] names;
        uint256[] ids;
        uint256[] mintPrices;
        uint256[] maxSupplys;
    }
}
