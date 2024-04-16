// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Toqen} from "../src/Toqen.sol";

// forge script script/Toqen.s.sol --fork-url http://localhost:8545 --broadcast
//
// Toqen: 0x5FbDB2315678afecb367f032d93F642f64180aa3

contract ToqenScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(privateKey);

        Toqen toqen = new Toqen();
        console.log("Toqen:", address(toqen));

        vm.stopBroadcast();
    }
}
