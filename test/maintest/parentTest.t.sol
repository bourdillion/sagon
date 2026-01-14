// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {MockToken} from "../setup/MockToken.sol";
import {FailMockToken} from "../setup/FailMockToken.sol";
import {ISagon} from "../../src/interface/ISagon.sol";
import {SagonNoYul} from "../../src/core/sagonNoYul.sol";
import {FeeOnTransferToken} from "../setup/FeeOnTransferToken.sol";

contract ParentTest is Test {
    ISagon public sagon;
    MockToken public mockToken;
    FailMockToken public failMockToken;
    FeeOnTransferToken public feeToken;

    address sender = makeAddr("sender");

    function setUp() public {
        sagon = ISagon(address(new SagonNoYul()));
        mockToken = new MockToken();
        failMockToken = new FailMockToken();
        feeToken = new FeeOnTransferToken();
    }

    /*
     * ============================================================================
     * TESTING REGULAR PATHWAY FOR FUNCTION sendBatchToken
     * ============================================================================
     */

    function testSendBatchTokensWork(address[] calldata recipients, uint256[] calldata amounts) public {
        //No need to assume if both lists of addresses are the same as we will eventually modify the data a bit
        //Arrange
        vm.assume(recipients.length != 0 && amounts.length != 0);
        address[] memory newRecipients = cleanAddresses(recipients, sender);

        uint256 totalAmounts;
        uint256[] memory allAmounts = new uint256[](newRecipients.length);
        for (uint256 i = 0; i < newRecipients.length; i++) {
            uint256 idx = amounts[i % amounts.length];
            uint256 storedAmount = (idx % newRecipients.length) == 0 ? 1 : (idx % newRecipients.length);
            totalAmounts += storedAmount;
            allAmounts[i] = storedAmount;
        }

        console2.log("Total amount to be sent", totalAmounts);
        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        uint256 initGas = gasleft();
        sagon.sendBatchToken(address(mockToken), newRecipients, allAmounts, totalAmounts);
        uint256 gasUsed = initGas - gasleft();
        console2.log("Gas used", gasUsed);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), 0, "Incorrect sender balance");

        // Sum expected balances per unique recipient to handle duplicates
        address[] memory uniq = new address[](newRecipients.length);
        uint256[] memory expected = new uint256[](newRecipients.length);
        uint256 uniqCount = 0;

        for (uint256 i = 0; i < newRecipients.length; i++) {
            address r = newRecipients[i];
            bool found = false;
            for (uint256 k = 0; k < uniqCount; k++) {
                if (uniq[k] == r) {
                    expected[k] += allAmounts[i];
                    found = true;
                    break;
                }
            }
            if (!found) {
                uniq[uniqCount] = r;
                expected[uniqCount] = allAmounts[i];
                uniqCount++;
            }
        }

        for (uint256 i = 0; i < uniqCount; i++) {
            assertEq(mockToken.balanceOf(uniq[i]), expected[i], "Incorrect recipient balance");
        }
    }

    /*
     * ============================================================================
     * EDGE CASE TESTING FOR FUNCTION sendBatchToken
     * ============================================================================
     */

    /*
     * ============================================================================
     * HELPER FUNCTION FOR FUZZ
     * ============================================================================
     */

    function cleanAddresses(address[] memory recipients, address sendingAddress)
        internal
        pure
        returns (address[] memory goodAddresses)
    {
        uint256 len = recipients.length;
        uint256 count;

        //First get the count of the good array of addresses
        for (uint256 i = 0; i < len; i++) {
            address r = recipients[i];
            if (r != address(0) && r != sendingAddress) {
                count++;
            }
        }

        goodAddresses = new address[](count);

        // Now filling up the array with the good addresses
        uint256 j;
        for (uint256 i = 0; i < len; i++) {
            address r = recipients[i];
            if (r != address(0) && r != sendingAddress) {
                goodAddresses[j++] = r;
            }
        }
    }
}
