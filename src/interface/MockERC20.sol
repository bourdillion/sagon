// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    //uint256 public constant MINT_AMOUNT_FOR_SENDER = 1e18;

    constructor() ERC20("Mock Token", "MCKTKN") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
