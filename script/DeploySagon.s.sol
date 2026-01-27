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

        SagonNoYul sagonNoYul = new SagonNoYul();
        Sagon sagon = new Sagon();

        ISagon sagonSol = ISagon(address(sagonNoYul));
        ISagon sagonAssembly = ISagon(address(sagon));

        console.log("SagonPureSolidity contract deployed at:", address(sagonSol));
        console.log("SagonAssembly contract deployed at:", address(sagonAssembly));

        vm.stopBroadcast();
    }
}
