import hre from "hardhat";
import { ethers } from "hardhat";
import { encodePacked } from 'viem';

const ENTRY_POINT_V7 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";
export const irrelevantOwner = "0x2cf491602ad22944D9047282aBC00D3e52F56B37";
export const EOAOnboardingFactoryOwner = "0x2cf491602ad22944D9047282aBC00D3e52F56B37";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider?.getBalance(deployer.address))?.toString());

  try {
    // Deploy Default Validator
    console.log("\nDeploying DefaultValidator...");
    const DefaultValidator = await ethers.getContractFactory("ECDSAValidator");
    const defaultValidator = await DefaultValidator.deploy();
    await defaultValidator.waitForDeployment();
    const defaultValidatorAddress = await defaultValidator.getAddress();
    console.log("DefaultValidator deployed to:", defaultValidatorAddress);
    const initData = encodePacked(['address'], [irrelevantOwner]);
    console.log("Init data:", initData);

    // Deploy Bootstrap
    console.log("\nDeploying Bootstrap...");
    const Bootstrap = await ethers.getContractFactory("Bootstrap");
    const bootstrap = await Bootstrap.deploy(defaultValidatorAddress, initData);
    await bootstrap.waitForDeployment();
    const bootstrapAddress = await bootstrap.getAddress();
    console.log("Bootstrap deployed to:", bootstrapAddress);

    // Deploy StartaleSmartAccount
    console.log("\nDeploying StartaleSmartAccount...");
    const StartaleSmartAccount = await ethers.getContractFactory("StartaleSmartAccount");
    
    // Get gas estimate
    const startaleSmartAccount = await StartaleSmartAccount.deploy(ENTRY_POINT_V7, defaultValidatorAddress, initData);
    const deployTx = await startaleSmartAccount.deploymentTransaction();
    if (!deployTx) {
      throw new Error("Failed to get deployment transaction");
    }
    const gasEstimate = await deployer.estimateGas({
      data: deployTx.data,
      to: deployTx.to,
      value: deployTx.value,
      from: deployer.address
    });
    console.log("Estimated gas for deployment:", gasEstimate.toString());
    
    // Get current gas price
    const feeData = await deployer.provider?.getFeeData();
    const gasPrice = feeData?.gasPrice;
    console.log("Current gas price:", gasPrice?.toString());
    
    // Calculate estimated deployment cost
    if (gasPrice) {
      const estimatedCost = gasEstimate * gasPrice;
      console.log("Estimated deployment cost (wei):", estimatedCost.toString());
      console.log("Estimated deployment cost (ETH):", ethers.formatEther(estimatedCost));
    }

    await startaleSmartAccount.waitForDeployment();
    const startaleSmartAccountAddress = await startaleSmartAccount.getAddress();
    console.log("StartaleSmartAccount deployed to:", startaleSmartAccountAddress);

    const BrandNewECDSAValidator = await ethers.getContractFactory("ECDSAValidator");
    const brandNewECDSAValidator = await BrandNewECDSAValidator.deploy();
    await brandNewECDSAValidator.waitForDeployment();
    const brandNewECDSAValidatorAddress = await brandNewECDSAValidator.getAddress();
    console.log("BrandNewECDSAValidator deployed to:", brandNewECDSAValidatorAddress);

    // Deploy EOAOnboardingFactory
    console.log("\nDeploying EOAOnboardingFactory...");
    const EOAOnboardingFactory = await ethers.getContractFactory("EOAOnboardingFactory");
    const eoaOnboardingFactory = await EOAOnboardingFactory.deploy(
      startaleSmartAccountAddress,
      EOAOnboardingFactoryOwner,
      brandNewECDSAValidatorAddress,
      bootstrapAddress
    );
    await eoaOnboardingFactory.waitForDeployment();
    const eoaOnboardingFactoryAddress = await eoaOnboardingFactory.getAddress();
    console.log("EOAOnboardingFactory deployed to:", eoaOnboardingFactoryAddress);

  } catch (error: any) {
    console.error("Deployment failed with error:", error);
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error("Error: Insufficient funds for deployment");
    } else if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
      console.error("Error: Gas estimation failed");
    } else if (error.code === 'NETWORK_ERROR') {
      console.error("Error: Network connection issue");
    } else if (error.code === 'TIMEOUT') {
      console.error("Error: Transaction timeout");
    } else {
      console.error("Unknown error:", error);
    }
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


