import { ethers } from "hardhat";

module.exports = async () => {
    const deployer = (await ethers.getSigners())[0];
    const cstAdress = "0xb77b6658155Ce1a194Fc9a128E4FAF6e569FF69e";
    const CSTStakingContract = await ethers.getContractFactory("CSTStaking");
    const csTStaking = await CSTStakingContract.deploy(cstAdress, deployer);
    await csTStaking.waitForDeployment();
    console.log("CSTStaking deployed:", await csTStaking.getAddress());
};
module.exports.tags = ["CSTStaking"];
