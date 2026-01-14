// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISagon} from "../interface/ISagon.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SagonNoYul
 * @author insecureMary
 * @author bourdillion
 * @notice This is a pure solidity implementation of of the Sagon contract, used only for reference in the huff and assembly implementation.
 * This implementation is less optimized for gas usage.
 * Sagon enables batch distribution of ERC20 tokens to multiple addresses at a go. Amounts to be distrubuted could either be the same amounts or different amounts.
 *@dev this contract has an O(n) complexity and could cost huge amounts of gas if the list is too long. If using this contract to batchsend tokens, its best to break the list to smaller ones to save gas.
 */
contract SagonNoYul is ISagon {
    /**
     * @notice function for distributing tokens in batch to mutiple address
     * @param tokenToSend The address of the ERC20 token to be distributed
     * @param recipients The list of addresses to send the token to
     * @param amounts the list of amounts to send for each address on the list
     * @param expectedTotal The total amount that will be distributed to all the addresses.
     */
    function sendBatchToken(
        address tokenToSend,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 expectedTotal
    ) public {
        if (tokenToSend == address(0)) revert Sagon__ZeroAddressForToken();
        if (expectedTotal == 0) revert Sagon__ZeroTotalAmountNotAllowed();
        if (recipients.length != amounts.length) revert Sagon__LengthMismatch();
        bool isValid = isListValid(recipients, amounts);
        if (!isValid) revert Sagon__ZeroInputsNotAllowed();
        uint256 actualTotal;
        bool success = IERC20(tokenToSend).transferFrom(msg.sender, address(this), expectedTotal);
        if (!success) revert Sagon__TransferFailed();
        for (uint256 i; i < recipients.length; i++) {
            actualTotal += amounts[i];
            success = IERC20(tokenToSend).transfer(recipients[i], amounts[i]);
            if (!success) revert Sagon__TransferFailed();
        }
        if (actualTotal != expectedTotal) {
            revert Sagon__AmountsMismatch();
        }
        emit TokensDistributed(tokenToSend, actualTotal, msg.sender);
    }

    /**
     * @notice function for checking validity of lists
     * @param recipients The list of addresses to be checked
     * @param amounts the list of amounts to check for each address on the list
     * @return bool If list is valid it returns true, otherwise false
     */
    function isListValid(address[] calldata recipients, uint256[] calldata amounts) public pure returns (bool) {
        if (amounts.length == 0) {
            return false;
        }

        for (uint256 i; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                return false;
            }
        }
        for (uint256 i; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                return false;
            }
        }

        return true;
    }
}
