// // SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Sagon Contract
 * @author insecureMary
 * @author bourdillion
 * @notice Assembly Implementation of the Sagon contract
 * This is a more gas efficient implementation of Sagon. As it is written mostly in assembly, it processes faster and thus costs lesser gas than the pure solidity implementation.
 * Sagon enables batch distribution of ERC20 tokens to multiple addresses at a go. Amounts to be distrubuted could either be the same amounts or different amounts.
 *@dev this contract has an O(n) complexity and could cost huge amounts of gas if the list is too long. If using this contract to batchsend tokens, its best to break the list to smaller ones to save gas.
 */
contract Sagon {
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
        assembly {
            // check for equal lengths
            if iszero(eq(recipients.length, amounts.length)) {
                mstore(0x00, 0x638ed181) // cast sig "Sagon__LengthMismatch()"
                revert(0x1c, 0x04)
            }

            // transferFrom(address from, address to, uint256 amount)
            // cast sig "transferFrom(address,address,uint256)"
            // 0x00: 0x23b872dd00000000000000000000000000000000000000000000000000000000(= function sig)
            mstore(0x00, hex"23b872dd")
            // from address
            mstore(0x04, caller())
            // to address (this contract)
            mstore(0x24, address())
            // total amount
            mstore(0x44, expectedTotal)

            //@dev for tokens that do not have a return value on transfer, this call could silently fail and the funtion will continue as normal.
            if iszero(call(gas(), tokenToSend, 0, 0x00, 0x64, 0, 0)) {
                mstore(0x00, 0x9b9a643c) // cast sig "Sagon__TransferFailed()"
                revert(0x1c, 0x04)
            }

            // transfer(address to, uint256 value)
            mstore(0x00, hex"a9059cbb")
            // end of array
            // recipients.offset actually points to the recipients.length offset, not the first address of the array offset
            let end := add(recipients.offset, shl(5, recipients.length))
            let diff := sub(recipients.offset, amounts.offset)

            // Checking totals at the end
            let actualTotal := 0
            for {
                let addressOffset := recipients.offset
            } 1 {} {
                let recipient := calldataload(addressOffset)

                // Check to address
                if iszero(recipient) {
                    mstore(0x00, 0xb6aff06b) // cast sig "Sagon__ZeroInputsNotAllowed()"
                    revert(0x1c, 0x04)
                }

                // to address
                mstore(0x04, recipient)
                // amount
                mstore(0x24, calldataload(sub(addressOffset, diff)))
                // Keep track of the total amount
                actualTotal := add(actualTotal, mload(0x24))

                // transfer the tokens
                if iszero(call(gas(), tokenToSend, 0, 0x00, 0x44, 0, 0)) {
                    mstore(0x00, 0x9b9a643c) // cast sig "TSender__TransferFailed()"
                    revert(0x1c, 0x04)
                }

                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) {
                    break
                }
            }

            // Check if the totals match
            if iszero(eq(actualTotal, expectedTotal)) {
                mstore(0x00, 0xc6a7838d) // cast sig "Sagon__AmountsMismatch()"
                revert(0x1c, 0x04)
            }
        }
    }

    /**
     * @notice function for checking validity of lists. No need to try to optimise it, as we will not be calling it in the main function. It is just a staticall.
     * @param recipients The list of addresses to be checked
     * @param amounts the list of amounts to check for each address on the list
     * @return bool If list is valid it returns true, otherwise false
     */
    function isListValid(address[] calldata recipients, uint256[] calldata amounts) public pure returns (bool) {
        if (amounts.length == 0) {
            return false;
        }

        if (recipients.length != amounts.length) {
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
