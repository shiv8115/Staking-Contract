module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    // deploy reward token
    const rewardToken = await deploy("RewardToken", {
        from: deployer,
        args: [10000],
        log: true,
    });

    // deploy staking token
    const stakingToken = await deploy("stakingToken", {
        from: deployer,
        args: ["StakingToken", "STN", 10000],
        log: true,
    });

    // deploy upgradable staking pool contract
    const StakingContract = await deploy('StakingContract', {
        from: deployer,
        proxy: {
        owner: deployer,
        proxyContract: 'OpenZeppelinTransparentProxy',
        execute: {
        methodName: 'initialize',
        args: [100, 500, rewardToken.address],
        },
        upgradeIndex: 0,
        }
      });

    console.log("Reward address : ", rewardToken.address);
    console.log("Staking Token address : ", stakingToken.address);
    console.log("Staking address : ", StakingContract.address);
}

module.exports.tags = ["all", "RewardToken", "stakingToken", "StakingContract"];