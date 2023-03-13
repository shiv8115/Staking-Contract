// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Staking.sol";

contract Airdrop is ERC20, Ownable {

    // address of the staking contract
    address public stakingContractAddress; 
    uint256 public airdropReward;

    mapping(address => bool) public claimed;

    constructor(address _stakingContractAddress, uint256 _totalSupply, uint256 _airdropReward) ERC20("AirdropRewardToken", "MTK"){
        stakingContractAddress = _stakingContractAddress;
        airdropReward = _airdropReward;
        _mint(msg.sender, _totalSupply);
    }

    function claimReward(address _user) public {
        require(block.timestamp > StakingContract(stakingContractAddress).endTimestamp(), "Staking period not ended yet");
        require(!claimed[msg.sender], " Reward already claimed");
        require(StakingContract(stakingContractAddress).isWhitelistedUser(_user), "Invalid proof"); 
        claimed[msg.sender] = true;
    } 

    /// @dev this function used to get reward as airdrop
    function getReward(address user) external {
        require(claimed[user], "no reward to withdraw");
            // Transfer Airdrop_reward tokens to user
            require(
                IERC20Upgradeable(address(this)).transfer(
                    user,
                    airdropReward
                ),
                "Failed to transfer reward tokens"
            );
        }
}
    
