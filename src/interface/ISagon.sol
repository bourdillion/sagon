// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Sagon interface
 * @notice This is the interface for the implementation of Sagon contract. This contains all the necessary functions, errors and events for the Sagon contract.
 */
interface ISagon {
    //ERRORS
    error Sagon__ZeroInputsNotAllowed();
    error Sagon__ZeroTotalAmountNotAllowed();
    error Sagon__ZeroAddressForToken();
    error Sagon__TransferFailed();
    error Sagon__AmountsMismatch();
    error Sagon__LengthMismatch();

    //EVENTS
    event TokensDistributed(address indexed tokenToSend, uint256 indexed totalAmountSent, address sender);

    function sendBatchToken(
        address tokenToSend,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 totalAmountToSend
    ) external;

    function isListValid(address[] calldata recipients, uint256[] calldata amounts) external pure returns (bool);
}
