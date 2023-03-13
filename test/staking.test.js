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

	it("token should be added in whitelist token", async function () {
		await staking.addWhitelistToken(hardhatToken.address);
		const expected = true;
		expect(await staking.isWhitelistedToken(hardhatToken.address)).to.equal(expected);
	});

	it("only owner should add token in white list", async function () {
		const [owner, addr1, addr2] = await ethers.getSigners();
		const expected = true;
		await expect(staking.connect(addr1).addWhitelistToken(hardhatToken.address)).to.be.revertedWith("AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
	});

	it("Whitelisted element can be removed by owner", async function () {
		//add token
		await staking.addWhitelistToken(rewardToken.address);
		const expected = true;
		//check for existance
		expect(await staking.isWhitelistedToken(rewardToken.address)).to.equal(expected);
		//remove token
		const output = false;
		await staking.removeWhitelistToken(rewardToken.address);
		expect(await staking.isWhitelistedToken(rewardToken.address)).to.equal(output);
	});

	it("should reverted if user not remove element", async function () {
		const [owner, addr1] = await ethers.getSigners();
		//add token
		await staking.addWhitelistToken(rewardToken.address);
		const expected = true;
		//check for existance
		expect(await staking.isWhitelistedToken(rewardToken.address)).to.equal(expected);
		//remove token
		await expect(staking.connect(addr1).removeWhitelistToken(rewardToken.address)).to.be.revertedWith("AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
	});

	it("should revert if staking amount less than zero", async function() {
		const [owner, addr1] = await ethers.getSigners();
		await hardhatToken.approve(staking.address, 100000);
		await expect(staking.stake(hardhatToken.address, 0)).to.be.revertedWith("Amount must be greater than zero");

	});

	it("user should able to stake only whitelisted token", async function () {
		const [owner, addr1] = await ethers.getSigners();
		await hardhatToken.approve(staking.address, 100000);
		await staking.stake(hardhatToken.address, 50);
		expect(await hardhatToken.balanceOf(staking.address)).to.equal(50);
		const balance = await hardhatToken.balanceOf(staking.address);
	});

	it("should emit event of staking", async function() {
		const [owner] = await ethers.getSigners();
		await expect(staking.stake(hardhatToken.address, 50))
        .to.emit(staking, "Staked")
        .withArgs(owner.address, hardhatToken.address, 50);
	});


});
