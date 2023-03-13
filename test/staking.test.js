const { ethers } = require("hardhat");
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

let rewardToken,hardhatToken, staking, airdrop; 

describe("Staking Contract", function() {
    let rewardContract;
    async function deployTokenFixture() {
        const Token = await ethers.getContractFactory("StakingToken");
        const [owner] = await ethers.getSigners();
        hardhatToken = await Token.deploy("shivam","SKY", 100000);
        await hardhatToken.deployed();
        // Fixtures can return anything you consider useful for your tests
        return { Token, hardhatToken, owner};
    }

    async function deployRewardTokenFixture() {
        const TokenReward = await ethers.getContractFactory("RewardToken");
        const [RewardOwner] = await ethers.getSigners();
        rewardToken = await TokenReward.deploy(500000);
        await rewardToken.deployed();
        return { TokenReward, rewardToken, RewardOwner};
    }

	async function deployStakingFixture() {
		const Staking = await ethers.getContractFactory("StakingContract");
		const startTime = Math.floor(Date.now() / 1000);
    	const endTime = Math.floor(Date.now() / 1000) + 172800;
		staking = await upgrades.deployProxy(Staking, [startTime, endTime, rewardToken.address], {
			initializer: "initialize",
		  });
		await staking.deployed();
		console.log("staking contract", staking.address);
		return {Staking, staking};
	}

	async function deployAirdropFixture() {
		const Airdrop = await ethers.getContractFactory("Airdrop");
		airdrop = await Airdrop.deploy(staking.address, 1000000, 100);
		await airdrop.deployed();
		return {Airdrop, airdrop};
	}

    it("Should assign the total supply of Stakingtokens to the owner", async function () {
        const { hardhatToken, owner } = await loadFixture(deployTokenFixture);
        const ownerBalance = await hardhatToken.balanceOf(owner.address);
        console.log("staking Token", hardhatToken.address);
		let name = await hardhatToken.name();
		let supply = await hardhatToken.totalSupply();
		console.log("staking Token name", name);
		console.log("staking Token total supply", supply);
        expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Should assign the total supply of Reward tokens to the owner", async function () {
        const {rewardToken, RewardOwner } = await loadFixture(deployRewardTokenFixture);
        const ownerBalance = await rewardToken.balanceOf(RewardOwner.address);
        console.log("Reward token" ,rewardToken.address);
		let name = await rewardToken.name();
		let supply = await rewardToken.totalSupply();
		console.log("Reward Token name", name);
		console.log("Reward Token total supply", supply);
        expect(await rewardToken.totalSupply()).to.equal(ownerBalance);
        });

	it("deploy staking contract", async function () {
		const {staking} = await loadFixture(deployStakingFixture);
	})

	it("Should assign the total supply of airdrop tokens to the owner", async function () {
		const [owner] = await ethers.getSigners();
		const {airdrop} = await loadFixture(deployAirdropFixture);
		const ownerBalance = await airdrop.balanceOf(owner.address);
		expect(await airdrop.totalSupply()).to.equal(ownerBalance);
	})

	it("should name and symbol initialize correctly of airdrop token", async function() {
		const expectedName = "AirdropRewardToken";
		const expectedSymbol = "MTK";
		expect(await airdrop.name()).to.equal(expectedName);
		expect(await airdrop.symbol()).to.equal(expectedSymbol);
	})
});
