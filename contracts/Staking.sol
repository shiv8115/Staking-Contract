// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract StakingContract is Initializable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint256 public constant REWARD_PER_BLOCK = 1; // 1 reward token per 5 blocks
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    address _rewardToken;
    EnumerableSetUpgradeable.AddressSet private _whitelistedToken;// set that consist of address of token that are able for staking

    // map used to store user amount that are staked user => tokenAddress => amount
    mapping(address => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => uint256)) private _lastUpdateBlock; // user => token => last update block number

    mapping(address => uint256) private _rewards; // user => total rewards

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    function initialize(uint256 _startTimestamp, uint256 _endTimestamp,address rewardToken) external initializer{
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        _rewardToken = rewardToken;
    }
    // this modifier used to check time duration of staking
    modifier onlyWhileOpen(){
        require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "Duration over");
        _;
    }

    //It is used to check token address are whitelisted or not, if address found in set it means white token else not white token
    modifier onlyWhitelistedToken(address _token){
        require(_whitelistedToken.contains(_token),"Token is not whitelisted");
        _;
    }

    //This function used to add white token into set by contract owner
    function addWhitelistToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE){
        _whitelistedToken.add(_token);
    }

    //this function used to remove whitelisted token from set by contract owner
    function removeWhitelistToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE){
        _whitelistedToken.remove(_token);
    }

    //This is used to check whether the token is white listed or not.
    function isWhitelistedToken(address token) external view returns (bool) {
        return _whitelistedToken.contains(token);
    }

    //this is used for enquiry of token staked of user.
    function balanceOf(address user, address token) external view returns(uint256){
        return _balances[user][token];
    }

    //This function used for staking token of amount value
    function stake(address token, uint256 amount) 
        external 
        onlyWhileOpen 
        onlyWhitelistedToken(token){
        IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);//transfer token from user to staking pool
        _balances[msg.sender][token] += amount;// update information of staking token of corresponding users
        _lastUpdateBlock[msg.sender][token] = block.number;// set the current block number
        emit Staked(msg.sender, token, amount); // emit event after staking
    }

    //this function withdraw given amount of token from staking pool
    function withdraw(address token, uint256 amount) 
        public 
        onlyWhitelistedToken(token){
        //checkpoint for checking sufficient balance
        require(_balances[msg.sender][token] >= amount, "Insufficient balance");
        _updateRewards(msg.sender, token);

        //transfer token from staking pool to user
        IERC20Upgradeable(token).transfer(msg.sender, amount);

        //update balance of staking amount of corresponding user
        _balances[msg.sender][token] -= amount;

        //update the current block
        _lastUpdateBlock[msg.sender][token] = block.number;

        //emit event after successful withdraw of tokens
        emit Withdrawn(msg.sender, token, amount);
    }

    function getReward() external {
        uint256 reward = _rewards[msg.sender];
        if (reward > 0) {
            _rewards[msg.sender] = 0;
            emit RewardPaid(msg.sender, reward);
            // Transfer reward tokens to user
            require(IERC20Upgradeable(_rewardToken).transfer(msg.sender, reward), "Failed to transfer reward tokens");
        }
    }
    //this function used to get total earned token in staking
    function earned(address user) public view returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < _whitelistedToken.length(); i++) {
            address token = _whitelistedToken.at(i);
            uint256 reward = (block.number - _lastUpdateBlock[user][token]) / 5 * REWARD_PER_BLOCK;
            totalReward += reward;
        }
        return _rewards[user] + totalReward;
    }

    function _updateRewards(address user, address token) private {
      uint256 reward = (block.number - _lastUpdateBlock[user][token]) / 5 * REWARD_PER_BLOCK;
     _rewards[user] += reward;
     _lastUpdateBlock[user][token] = block.number;
    }
}
