// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    uint256 public constant MINT_AMOUNT_FOR_SENDER = 1e18;

    constructor() ERC20("Mock Token", "MCKTKN") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        _update(owner, to, value);
        return true;
    }
}
