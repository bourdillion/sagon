// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {MockToken} from "../setup/MockToken.sol";
import {FailMockToken} from "../setup/FailMockToken.sol";
import {FeeOnTransferToken} from "../setup/FeeOnTransferToken.sol";
import {ISagon} from "../../src/interface/ISagon.sol";
import {SagonNoYul} from "../../src/core/sagonNoYul.sol";

abstract contract ParentTest is Test {
    ISagon public sagon;
    MockToken public mockToken;
    FailMockToken public failMockToken;
    FeeOnTransferToken public feeToken;

    address sender = makeAddr("sender");

    function setUp() public virtual {
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

    function testRevertsWhenListsLengthsAreNotEqual(address[] calldata recipients, uint256[] calldata amounts) public {
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
        //Making lengths unequal
        uint256[] memory trimmed = new uint256[](allAmounts.length - 1);

        for (uint256 i; i < trimmed.length; i++) {
            trimmed[i] = allAmounts[i];
        }

        allAmounts = trimmed;

        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        vm.expectRevert(ISagon.Sagon__LengthMismatch.selector);
        sagon.sendBatchToken(address(mockToken), newRecipients, allAmounts, totalAmounts);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), totalAmounts, "Incorrect sender balance");
        //Assert that no recipient received tokens
        for (uint256 i = 0; i < newRecipients.length; i++) {
            assertEq(mockToken.balanceOf(newRecipients[i]), 0, "Incorrect recipient balance");
        }
        //Checking that no money is in the protocol
        assertEq(mockToken.balanceOf(address(sagon)), 0);
    }

    function testRevertsWhenInputsZeroAddressForToken(address[] calldata recipients, uint256[] calldata amounts)
        public
    {
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

        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        vm.expectRevert(ISagon.Sagon__ZeroAddressForToken.selector);
        sagon.sendBatchToken(address(0), newRecipients, allAmounts, totalAmounts);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), totalAmounts, "Incorrect sender balance");
        //Assert that no recipient received tokens
        for (uint256 i = 0; i < newRecipients.length; i++) {
            assertEq(mockToken.balanceOf(newRecipients[i]), 0, "Incorrect recipient balance");
        }
        //Checking that no money is in the protocol
        assertEq(mockToken.balanceOf(address(sagon)), 0);
    }

    function testRevertsWhenRecipientAddressIsZero(address[] calldata recipients, uint256[] calldata amounts) public {
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
        //Introducing zero address in the list
        newRecipients[0] = address(0);

        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        vm.expectRevert(ISagon.Sagon__ZeroInputsNotAllowed.selector);
        sagon.sendBatchToken(address(mockToken), newRecipients, allAmounts, totalAmounts);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), totalAmounts, "Incorrect sender balance");
        //Assert that no recipient received tokens
        for (uint256 i = 0; i < newRecipients.length; i++) {
            assertEq(mockToken.balanceOf(newRecipients[i]), 0, "Incorrect recipient balance");
        }
        //Checking that no money is in the protocol
        assertEq(mockToken.balanceOf(address(sagon)), 0);
    }

    function testRevertsWhenRecipientAmountIsZero(address[] calldata recipients, uint256[] calldata amounts) public {
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
        //Introducing zero amount in the list
        allAmounts[0] = 0;

        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        vm.expectRevert();
        sagon.sendBatchToken(address(mockToken), newRecipients, allAmounts, totalAmounts);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), totalAmounts, "Incorrect sender balance");
        //Assert that no recipient received tokens
        for (uint256 i = 0; i < newRecipients.length; i++) {
            assertEq(mockToken.balanceOf(newRecipients[i]), 0, "Incorrect recipient balance");
        }
        //Checking that no money is in the protocol
        assertEq(mockToken.balanceOf(address(sagon)), 0);
    }

    function testRevertsWhenTotalsDontMatch(address[] calldata recipients, uint256[] calldata amounts) public {
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
        //Modifying total amounts to not match
        totalAmounts += 1;

        vm.startPrank(sender);
        mockToken.mint(totalAmounts);
        console2.log("Sender balance", mockToken.balanceOf(sender));
        mockToken.approve(address(sagon), totalAmounts);
        vm.stopPrank();

        //Act
        vm.startPrank(sender);
        vm.expectRevert(ISagon.Sagon__AmountsMismatch.selector);
        sagon.sendBatchToken(address(mockToken), newRecipients, allAmounts, totalAmounts);
        vm.stopPrank();

        //Assert
        assertEq(mockToken.balanceOf(sender), totalAmounts, "Incorrect sender balance");
        //Assert that no recipient received tokens
        for (uint256 i = 0; i < newRecipients.length; i++) {
            assertEq(mockToken.balanceOf(newRecipients[i]), 0, "Incorrect recipient balance");
        }
        //Checking that no money is in the protocol
        assertEq(mockToken.balanceOf(address(sagon)), 0);
    }

    // function testRevertsWhenTransferFails(
    //     address[] calldata recipients,
    //     uint256[] calldata amounts
    // ) public {
    //     vm.assume(recipients.length != 0 && amounts.length != 0);
    //     address[] memory newRecipients = cleanAddresses(recipients, sender);
    //     uint256 totalAmounts;
    //     uint256[] memory allAmounts = new uint256[](newRecipients.length);
    //     for (uint256 i = 0; i < newRecipients.length; i++) {
    //         uint256 idx = amounts[i % amounts.length];
    //         uint256 storedAmount = (idx % newRecipients.length) == 0
    //             ? 1
    //             : (idx % newRecipients.length);
    //         totalAmounts += storedAmount;
    //         allAmounts[i] = storedAmount;
    //     }

    //     vm.startPrank(sender);
    //     failMockToken.mint(totalAmounts);
    //     console2.log("Sender balance", failMockToken.balanceOf(sender));
    //     failMockToken.approve(address(sagon), totalAmounts);
    //     vm.stopPrank();

    //     //Act
    //     vm.startPrank(sender);
    //     vm.expectRevert(ISagon.Sagon__TransferFailed.selector);
    //     sagon.sendBatchToken(
    //         address(failMockToken),
    //         newRecipients,
    //         allAmounts,
    //         totalAmounts
    //     );
    //     vm.stopPrank();

    //     //Assert
    //     assertEq(
    //         failMockToken.balanceOf(sender),
    //         totalAmounts,
    //         "Incorrect sender balance"
    //     );
    //     //Assert that no recipient received tokens
    //     for (uint256 i = 0; i < newRecipients.length; i++) {
    //         assertEq(
    //             failMockToken.balanceOf(newRecipients[i]),
    //             0,
    //             "Incorrect recipient balance"
    //         );
    //     }
    //     //Checking that no money is in the protocol
    //     assertEq(failMockToken.balanceOf(address(sagon)), 0);
    // }

    /*
     * ============================================================================
     * TESTS FOR isListValid (BOTH NORMAL AND EDGE CASES)
     * ============================================================================
     */

    function testIsListValidWorksForValidLists(address[] calldata recipients, uint256[] calldata amounts) public view {
        vm.assume(recipients.length != 0 && amounts.length != 0);
        address[] memory newRecipients = cleanAddresses(recipients, sender);

        // Deduplicate recipients so we don't fuzz with duplicate addresses as the Huff implementation may reject duplicates
        address[] memory tmp = new address[](newRecipients.length);
        uint256 uniqCount = 0;
        for (uint256 i = 0; i < newRecipients.length; i++) {
            address r = newRecipients[i];
            bool found = false;
            for (uint256 k = 0; k < uniqCount; k++) {
                if (tmp[k] == r) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                tmp[uniqCount++] = r;
            }
        }

        // Ensure we still have at least one recipient after cleaning/deduping
        vm.assume(uniqCount != 0);

        // Shrink array to unique recipients
        address[] memory uniqRecipients = new address[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uniqRecipients[i] = tmp[i];
        }

        // Build amounts array matching the (deduplicated) recipients
        uint256[] memory allAmounts = new uint256[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uint256 idx = amounts[i % amounts.length];
            uint256 storedAmount = (idx % uniqCount) == 0 ? 1 : (idx % uniqCount);
            allAmounts[i] = storedAmount;
        }

        bool isValid = sagon.isListValid(uniqRecipients, allAmounts);
        assertTrue(isValid, "List should be valid");
    }

    function testIsListValidReturnsFalseForInvalidAddress(address[] calldata recipients, uint256[] calldata amounts)
        public
        view
    {
        //Arranging invalid lists
        vm.assume(recipients.length != 0 && amounts.length != 0);
        address[] memory newRecipients = cleanAddresses(recipients, sender);

        // Deduplicate recipients so we don't fuzz with duplicate addresses as the Huff implementation may reject duplicates
        address[] memory tmp = new address[](newRecipients.length);
        uint256 uniqCount = 0;
        for (uint256 i = 0; i < newRecipients.length; i++) {
            address r = newRecipients[i];
            bool found = false;
            for (uint256 k = 0; k < uniqCount; k++) {
                if (tmp[k] == r) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                tmp[uniqCount++] = r;
            }
        }

        // Ensure we still have at least one recipient after cleaning/deduping
        vm.assume(uniqCount != 0);

        // Shrink array to unique recipients
        address[] memory uniqRecipients = new address[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uniqRecipients[i] = tmp[i];
        }

        // Build amounts array matching the (deduplicated) recipients
        uint256[] memory allAmounts = new uint256[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uint256 idx = amounts[i % amounts.length];
            uint256 storedAmount = (idx % uniqCount) == 0 ? 1 : (idx % uniqCount);
            allAmounts[i] = storedAmount;
        }
        //Introducing zero address in the list
        uniqRecipients[0] = address(0);

        bool isValid = sagon.isListValid(uniqRecipients, allAmounts);
        assertTrue(!isValid, "List should not be valid");
    }

    function testIsListValidReturnsFalseForInvalidAmount(address[] calldata recipients, uint256[] calldata amounts)
        public
        view
    {
        //Arranging invalid lists
        vm.assume(recipients.length != 0 && amounts.length != 0);
        address[] memory newRecipients = cleanAddresses(recipients, sender);

        // Deduplicate recipients so we don't fuzz with duplicate addresses as the Huff implementation may reject duplicates
        address[] memory tmp = new address[](newRecipients.length);
        uint256 uniqCount = 0;
        for (uint256 i = 0; i < newRecipients.length; i++) {
            address r = newRecipients[i];
            bool found = false;
            for (uint256 k = 0; k < uniqCount; k++) {
                if (tmp[k] == r) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                tmp[uniqCount++] = r;
            }
        }

        // Ensure we still have at least one recipient after cleaning/deduping
        vm.assume(uniqCount != 0);

        // Shrink array to unique recipients
        address[] memory uniqRecipients = new address[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uniqRecipients[i] = tmp[i];
        }

        // Build amounts array matching the (deduplicated) recipients
        uint256[] memory allAmounts = new uint256[](uniqCount);
        for (uint256 i = 0; i < uniqCount; i++) {
            uint256 idx = amounts[i % amounts.length];
            uint256 storedAmount = (idx % uniqCount) == 0 ? 1 : (idx % uniqCount);
            allAmounts[i] = storedAmount;
        }
        //Introducing zero amount in the list
        allAmounts[0] = 0;

        bool isValid = sagon.isListValid(uniqRecipients, allAmounts);
        assertTrue(!isValid, "List should not be valid");
    }

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
