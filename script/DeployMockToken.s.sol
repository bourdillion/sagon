// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MockERC20} from "../src/interface/MockERC20.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract DeployMockToken is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 mockToken = new MockERC20();
        console.log("MockToken deployed at:", address(mockToken));
        vm.stopBroadcast();
    }
}
