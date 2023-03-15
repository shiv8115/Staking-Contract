# Staking-Contract

Part 1: Write a Staking Contract 
Contract should be Upgradeable and TwoStepOwnable
Contract should contain a list of white listed ERC20 tokens which user can stake
Use OZs Enumerable Address Set to maintain the list
The whitelist can be updated by the owner of the contract
Use OZs AccessControl lib for putting role checks
The contract generates reward tokens for the user based on how long the user has staked their assets
1 reward token is to be given for every 5 blocks added in chain for users staking period.
There is start and end time of staking period, user cannot deposit before start and after end time
No reward is generated after the end time of the staking.
Part 2: Airdrop
Contract should be ownable
Airdrop is responsible for distributing he the rewards generated
Airdrop only works after the staking period has ended
Use merkle proofs to check if the user claim for reward is valid or not
Part 3: Deployment 
Write deployment scripts using hardhat-deploy package
Part 4: Tests 
Write tests for all functionalities
Coverage should be 100%
