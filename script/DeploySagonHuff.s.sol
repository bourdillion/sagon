// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISagon} from "../src/interface/ISagon.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HuffDeployer, HuffConfig} from "foundry-huff/HuffDeployer.sol";

contract DeploySagonHuff is Script {
    string public constant HUFF_VERSION_LOCATION = "core/sagon";

    /// @notice Deploys the Huff contract using the HuffDeployer flow
    /// @dev This script deploys the Huff contract without starting an external broadcast
    ///      to avoid conflicts between `vm.prank` and `vm.broadcast` inside the Huff helpers.
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        // Deploy a HuffConfig instance directly to avoid delegatecalling an undeployed library
        HuffConfig config = HuffDeployer.config();
        address sagonHuff = config.deploy(HUFF_VERSION_LOCATION);
        // vm.startBroadcast(deployerKey);

        // vm.stopBroadcast();
        console.log("SagonHuff contract deployed at:", sagonHuff);
    }

    //added huff contract deployment here
}
