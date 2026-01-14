// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SagonNoYul} from "../src/core/sagonNoYul.sol";
import {ISagon} from "../src/interface/ISagon.sol";
import {Sagon} from "../src/core/sagon.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract DeploySagon is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        ISagon sagonSol = ISagon(address(new SagonNoYul()));
        ISagon sagonAssembly = ISagon(address(new Sagon()));
        console.log("SagonPureSolidity contract deployed at:", address(sagonSol));
        console.log("SagonAssembly contract deployed at:", address(sagonAssembly));
        vm.stopBroadcast();
    }
}
