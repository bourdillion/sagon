// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Sagon interface
 * @notice This is the interface for the implementation of Sagon contract. This contains all the necessary functions, errors and events for the Sagon contract.
 */
interface ISagon {
    //ERRORS
    error Sagon__ZeroInputsNotAllowed(); //0xb6aff06b
    error Sagon__ZeroTotalAmountNotAllowed(); //0x5c50c3ea
    error Sagon__ZeroAddressForToken(); //0xd773faf9
    error Sagon__TransferFailed(); //0x9b9a643c
    error Sagon__AmountsMismatch(); //0xc6a7838d
    error Sagon__LengthMismatch(); //0x638ed181

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
