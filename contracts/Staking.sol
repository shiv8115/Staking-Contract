// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
@title Staking Contract
@author Shivam Singh
@dev A contract that allows users to stake ERC20 tokens for a set duration of time and earn rewards in return.
@dev This contract uses OpenZeppelin's AccessControlUpgradeable, EnumerableSetUpgradeable, IERC20Upgradeable and OwnableUpgradeable contracts.
@notice Staking can only be done during the specified time duration and with whitelisted tokens.
*/
contract StakingContract is AccessControlUpgradeable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint256 public constant REWARD = 1; // 1 reward token per 5 blocks

    //Timestamps for the start and end of the staking period.
    uint256 public startTimestamp; 
    uint256 public endTimestamp;

    //The block number at the end of the staking period.
    uint256 public blockAtEndTimestamp;

    //Address of the reward token contract
    address public rewardTokenContract;

    //Flag to track if the block number at the end of the staking period has been updated
    bool private flag;

    //A set of token addresses that are allowed for staking.
    EnumerableSetUpgradeable.AddressSet private _whitelistedToken; 

    // map used to store user amount that are staked user => tokenAddress => amount
    mapping(address => mapping(address => uint256)) private _balances;

    // A mapping used to store the last block number at which a user's balance was updated.
    mapping(address => mapping(address => uint256)) private _lastUpdateBlock; 

    //A mapping used to store each user's total rewards
    mapping(address => uint256) private _rewards; // user => total rewards

    /// @notice This event is emitted when user staked amount in staking .
    /// @param user  The user address.
    /// @param token token's contract address.
    /// @param amount The amount.
    event Staked(address indexed user, address indexed token, uint256 amount);

    /// @notice This event is emitted when user withdrawal amount from staking.
    /// @param user  The user address.
    /// @param token token's contract address.
    /// @param amount The amount.
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    /// @notice This event is emitted when user's reward paid to corresponding user.
    /// @param user  The user address.
    /// @param amount The reward amount.
    event RewardPaid(address indexed user, uint256 amount);

    /// @notice This event is emitted when user reward updated.
    /// @param user  The user address.
    event UpdateReward(address indexed user);

    /// @dev Modifier to check if the current time is within the staking duration.
    /// @dev Throws an error if the current time is outside of the staking duration.
    modifier onlyWhileOpen() {
        require(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp, "Duration over");
        _;
    }

    /**
    * @dev Modifier to check if a token address is whitelisted for staking.
    * @dev Throws an error if the token address is not whitelisted.
    * @param _token The address of the token being staked.
    */
    modifier onlyWhitelistedToken(address _token) {
        require(_whitelistedToken.contains(_token), "Token is not whitelisted");
        _;
    }

    /**
    * @dev Initializes the contract.
    * @param _startTimestamp The timestamp at which the staking period begins.
    * @param _endTimestamp The timestamp at which the staking period ends.
    * @param rewardToken The address of the reward token contract.
     */
    function initialize(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address rewardToken
    ) external initializer {
        require(_endTimestamp > _startTimestamp, "endTimestamp must be greater than startTimestamp");
        require(address(rewardToken) != address(0) ,"Address must be non zero address");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        rewardTokenContract = rewardToken;
    }

    /// @dev This function used to add white token into set by contract owner
    /// @param _token address of token.
    function addWhitelistToken(address _token)external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistedToken.add(_token);
    }

    /// @dev this function used to remove whitelisted token from set by contract owner
    /// @param _token address of token that are being to be removed
    function removeWhitelistToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistedToken.remove(_token);
    }

    /// @dev This function used for staking token of amount value
    /// @param token address of token that being to be staked
    /// @param amount the amount of token 
    function stake(address token, uint256 amount)
        external
        onlyWhileOpen
        onlyWhitelistedToken(token)
    {   
        require(amount > 0, "Amount must be greater than zero");
        bool success = IERC20Upgradeable(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert("staking transfer failed");
        }
        _balances[msg.sender][token] += amount; 
        _lastUpdateBlock[msg.sender][token] = block.number; 
        emit Staked(msg.sender, token, amount); 
    }

    /// @dev this function withdraw given amount of token from staking pool
    /// @param token address of token that user want to withdraw
    /// @param amount amount of token 
    function withdraw(address token, uint256 amount)
        external
        onlyWhitelistedToken(token) {
        //checkpoint for checking sufficient balance
        require(amount > 0, "amount must be greater than zero");
        require(_balances[msg.sender][token] >= amount, "Insufficient balance");
        _updateRewards(msg.sender, token);

        //transfer token from staking pool to user
        IERC20Upgradeable(token).transferFrom(address(this), msg.sender, amount);

        //update balance of staking amount of corresponding user
        _balances[msg.sender][token] -= amount;

        //balance tranfer to user
        getReward(msg.sender);
        //emit event after successful withdraw of tokens
        emit Withdrawn(msg.sender, token, amount);
    }

    /// @dev this function used to get reward
    /// @param user address of user
    function getReward(address user) internal {
        uint256 reward = _rewards[user];
        if (reward > 0) {
            _rewards[user] = 0;
            emit RewardPaid(user, reward);
            // Transfer reward tokens to user
            require(
                IERC20Upgradeable(rewardTokenContract).transfer(
                    user,
                    reward
                ),
                "Failed to transfer reward tokens"
            );
        }
    }

    /// @dev this function used to update block number at the end of timestamp
    function blockNumberAtEndTimestamp() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(!flag && block.timestamp > endTimestamp) {
            blockAtEndTimestamp = block.number;
            flag = true;
        }
    }

    /// @dev This function retrieves the current balance of token that user stake.
    /// @param user address of user
    /// @param token address of token
    /// @return The current value of balance of user.
    function balanceOf(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }
    /// @dev This function check given token is whitelisted or not
    /// @param token address of token that to be checked
    /// @return bool value either true or false, if whitelisted return true, otherwise false
    function isWhitelistedToken(address token) external view returns (bool) {
        return _whitelistedToken.contains(token);
    }

    /// @dev this function used to update reward of user 
    /// @param user address of user
    /// @param token address of token
    function _updateRewards(address user, address token) private {
        uint256 reward;
        if(block.timestamp > endTimestamp) {
            reward = ((block.number - blockAtEndTimestamp) / 5) * REWARD;
        }else {
            reward = ((block.number - _lastUpdateBlock[user][token]) / 5) * REWARD;
        }
        _rewards[user] += reward;
        if(block.timestamp >= startTimestamp && block.timestamp <= endTimestamp) {
            _lastUpdateBlock[user][token] = block.number;
        }
        emit UpdateReward(user);
    }
}
