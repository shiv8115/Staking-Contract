const { network, ethers, deployments } = require("hardhat");

describe("Staking Test", async function () {
    let staking, rewardToken, deployer, stakeAmount;

    beforeEach(async function () {
        const accounts = await ethers.getSigners();
        deployer = await accounts[0];
        await deployments.fixture(["rewardtoken","stakingToken", "staking"]); // deploys contracts
        staking = await ethers.getContractAt("StakingContract");
        stakingToken = await ethers.getContractAt("stakingToken");
        rewardToken = await ethers.getContractAt("RewardToken");
        stakeAmount = ethers.utils.parseEther("100000");
    });
    it("Should allow users to stake and claim rewards", async function () {
        console.log("address1", rewardToken.address);
    })
});