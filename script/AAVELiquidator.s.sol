// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AAVELiquidator} from "src/AAVELiquidator.sol";

contract LiquidatorScript is Script {
    AAVELiquidator public liquidator;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        liquidator = new AAVELiquidator(
            address(0x9c26CD2202f5bAf498225aF1B399296a66e5d0CF)
        );

        vm.stopBroadcast();
    }
}
