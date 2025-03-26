import { ethers } from "hardhat";

module.exports = async () => {
    const deployer = (await ethers.getSigners())[0];

    // deploying token
    const CSTokenContract = await ethers.getContractFactory("CSToken");
    const csToken = await CSTokenContract.deploy();
    await csToken.waitForDeployment();
    const cstAdress = await csToken.getAddress();
    console.log("CSToken deployed:", cstAdress);

    // deploying staking contract
    const CSTStakingContract = await ethers.getContractFactory("CSTStaking");
    const csTStaking = await CSTStakingContract.deploy(cstAdress, deployer);
    await csTStaking.waitForDeployment();
    console.log("CSTStaking deployed:", await csTStaking.getAddress());
};
module.exports.tags = ["CSToken"];
