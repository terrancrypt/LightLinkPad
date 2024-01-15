// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

// @dev Mock LPT token for testing on protocol
contract LightPadToken is ERC20, ERC20Permit {
    uint256 private constant FAUCET_AMOUNT = 100e18; // 100 LPT

    constructor()
        ERC20("Light Pad Token", "LPT")
        ERC20Permit("Light Pad Token")
    {}

    function faucet() public {
        _mint(msg.sender, FAUCET_AMOUNT);
    }
}
