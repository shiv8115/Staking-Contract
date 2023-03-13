const { ethers, deployments, getUnnamedAccounts, getNamedAccounts } = require("hardhat");

// describe("Staking Test", async function () {
//     let staking, rewardToken, deployer, stakeAmount;

//     beforeEach(async function () {
//         const accounts = await ethers.getSigners();
//         deployer = await accounts[0];
//         await deployments.fixture(["rewardtoken","stakingToken", "staking"]); // deploys contracts
//         staking = await ethers.getContractAt("StakingContract");
//         stakingToken = await ethers.getContractAt("stakingToken");
//         rewardToken = await ethers.getContractAt("RewardToken");
//     });
//     it("Should allow users to stake and claim rewards", async function () {
//         console.log("address1", rewardToken.address);
//     })
// });

const setup = deployments.createFixture(async () => {
	await deployments.fixture('RewardToken');
	const {simpleERC20Beneficiary} = await getNamedAccounts();
    const contract = await ethers.getContractAt('RewardToken');
	// const contracts = {
	// 	RewardToken: await ethers.getContractAt('RewardToken'),
	// };
	const users = await setupUsers(await getUnnamedAccounts(), contracts);
	return {
		contract,
		users,
		simpleERC20Beneficiary: await setupUser(simpleERC20Beneficiary, contracts),
	};
});

describe('SimpleERC20', function () {

    it('transfer fails', async function () {
		const {contract, users} = await setup();
		//console.log(contract);
	});
});
