import { ethers } from "hardhat";
import { encodePacked, toBytes } from 'viem';
export const ENTRY_POINT_V7 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";
export const irrelevantOwner = "0x2cf491602ad22944D9047282aBC00D3e52F56B37";
export const EOAOnboardingFactoryOwner = "0x2cf491602ad22944D9047282aBC00D3e52F56B37";

async function main() {
  const ECDSAValidator = await ethers.getContractFactory("ECDSAValidator");
  const ecdsaValidator = await ECDSAValidator.deploy();
  const ecdsaValidatorAddress = await ecdsaValidator.getAddress();
  console.log("ECDSAValidator deployed to:", ecdsaValidatorAddress);

  const initData = encodePacked(['address'], [irrelevantOwner]);
  console.log("Init data:", initData);

  const Bootstrapper = await ethers.getContractFactory("Bootstrap");
  const bootstrapper = await Bootstrapper.deploy(ecdsaValidatorAddress, initData);
  await bootstrapper.waitForDeployment();
  const bootstrapperAddress = await bootstrapper.getAddress();
  console.log("Bootstrapper deployed to:", bootstrapperAddress);


  const StartaleSmartAccount = await ethers.getContractFactory("StartaleSmartAccount");


  const defaultValidator = await ecdsaValidator.getAddress();
  console.log("Default validator:", defaultValidator);

  const startaleSmartAccount = await StartaleSmartAccount.deploy(ENTRY_POINT_V7, defaultValidator, initData);
  await startaleSmartAccount.waitForDeployment();
  const startaleSmartAccountAddress = await startaleSmartAccount.getAddress();

  console.log("StartaleSmartAccount Implementation deployed to:", startaleSmartAccountAddress);

  const EOAOnboardingFactory = await ethers.getContractFactory("EOAOnboardingFactory");
  const eoaOnboardingFactory = await EOAOnboardingFactory.deploy(startaleSmartAccountAddress, EOAOnboardingFactoryOwner, ecdsaValidatorAddress, bootstrapperAddress);
  await eoaOnboardingFactory.waitForDeployment();
  const eoaOnboardingFactoryAddress = await eoaOnboardingFactory.getAddress();
  console.log("EOAOnboardingFactory deployed to:", eoaOnboardingFactoryAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


