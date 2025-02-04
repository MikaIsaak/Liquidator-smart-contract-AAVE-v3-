// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AAVELiquidator} from "../src/AAVELiquidator.sol";

contract AAVELiquidatorTest is Test {
    AAVELiquidator public liquidator;
    string RPC_URL = "https://rpc-test.haust.network";

    function setUp() public {
        uint256 testnetFork = vm.createFork(RPC_URL);
        vm.selectFork(testnetFork);
        vm.startPrank(0x378cd8af7a50026E17b7C2Bb286a7d4568C1F767);
        liquidator = new AAVELiquidator(
            0x9c26CD2202f5bAf498225aF1B399296a66e5d0CF
        );
        // function deal(address token, address to, uint256 give) public;
        deal(
            0xC33299bb1Beb4DD431A4CC8f4174395F0d1d29E7,
            address(liquidator),
            1000000000000000000
        );
        deal(
            0x25527108071D56bCBe025711CD93eE1E364b03ea,
            address(liquidator),
            1000000000000000000
        );
    }

    function test_Liquidator() public {
        liquidator.executeLiquidation(
            0xC33299bb1Beb4DD431A4CC8f4174395F0d1d29E7,
            0x25527108071D56bCBe025711CD93eE1E364b03ea,
            0x5C2490131Be84a313769156ab86c203941b482B2,
            2061,
            false
        );
    }
}
