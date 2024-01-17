// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { BaseScript } from "./Base.s.sol";
import { PoolFactory } from "../src/PoolFactory.sol";
import { console } from "forge-std/console.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    //solhint-disable no-empty-blocks
    function run() public broadcast { 
        PoolFactory factory = new PoolFactory();
        console.log("PoolFactory deployed at address: %s", address(factory));
    }
}
