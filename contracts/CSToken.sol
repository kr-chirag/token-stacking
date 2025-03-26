// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CSToken is ERC20 {
    constructor() ERC20("CSToken", "CST") {}

    function mint(uint256 _tokenCountToMint) public {
        _mint(msg.sender, _tokenCountToMint * 10 ** decimals());
    }
}
