// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract RewardToken is ERC20{
    constructor() ERC20("RewardToken", "MTK") {
         _mint(msg.sender, 5000);
    }
}