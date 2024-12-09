// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LaunchPadUtils} from "../modules/launchPadV1/LaunchPadUtils.sol";

contract LamboToken2 is ERC20, Ownable, LaunchPadUtils  {
    constructor(address pool, string memory _name, string memory _symbol)
        ERC20 (
            string(abi.encodePacked(_name, " (Lambo.win) ")),
            _symbol
        )
        Ownable(msg.sender)
    {
        _mint(pool, QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX);
    }

    function decimals() public view override returns (uint8) {
        return 9;
    }
}
