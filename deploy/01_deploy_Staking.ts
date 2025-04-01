import { ethers } from "hardhat";

module.exports = async () => {
    const deployer = (await ethers.getSigners())[0];
    const token = `${process.env.TOKEN_ADDRESS}`;
    console.log("deploying Staking with token:", token);

    const CSTStakingContract = await ethers.getContractFactory("Staking");
    const csTStaking = await CSTStakingContract.deploy(token, deployer);

    // deploying staking contract
    await csTStaking.waitForDeployment();
    console.log("Staking Contract deployed:", await csTStaking.getAddress());
};
module.exports.tags = ["Staking"];
