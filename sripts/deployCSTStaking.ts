import { ethers } from "hardhat";

async function main() {
    const deployer = (await ethers.getSigners())[0];
    const cstAdress = "0xb77b6658155Ce1a194Fc9a128E4FAF6e569FF69e";
    const CSTStakingContract = await ethers.getContractFactory("CSTStaking");
    const csTStaking = await CSTStakingContract.deploy(cstAdress, deployer, 30);
    console.log("deploying CSTStaking...");
    await csTStaking.waitForDeployment();
    console.log("CSTStaking deployed:", await csTStaking.getAddress());
}

main().catch(console.log);
