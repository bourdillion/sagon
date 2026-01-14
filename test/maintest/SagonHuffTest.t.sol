// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ParentTest} from "./parentTest.t.sol";
import {ISagon} from "../../src/interface/ISagon.sol";
import {MockToken} from "../setup/MockToken.sol";
import {FailMockToken} from "../setup/FailMockToken.sol";
import {FeeOnTransferToken} from "../setup/FeeOnTransferToken.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

contract SagonHuffTest is ParentTest {
    string public constant HUFF_VERSION_LOCATION = "core/sagon";

    function setUp() public override {
        sagon = ISagon(HuffDeployer.config().deploy(HUFF_VERSION_LOCATION));
        mockToken = new MockToken();
        failMockToken = new FailMockToken();
        feeToken = new FeeOnTransferToken();
    }
}
