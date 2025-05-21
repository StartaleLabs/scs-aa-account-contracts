// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import '../src/deployer/Deployer.sol';
import {Script, console} from 'forge-std/Script.sol';

contract DeployStartaleAccountImplementationCreate3 is Script {
  Deployer deployerInstance;
  address entryPoint;
  mapping(uint256 => uint256) public DEPLOYMENT_CHAIN_GAS_PRICES;

  error NoGasPriceSet();
  error ContractDeploymentFailed();

  function setUp() public {
    deployerInstance = Deployer(vm.envAddress('DEPLOYER_CONTRACT_ADDRESS')); // Set Deployer contract
    // EntryPoint v0.7 address
    entryPoint = vm.parseAddress('0x0000000071727De22E5E9d8BAf0edAc6f37da032');
    DEPLOYMENT_CHAIN_GAS_PRICES[1946] = 0.002 gwei;
    DEPLOYMENT_CHAIN_GAS_PRICES[1868] = 0.001 gwei;
  }

  function run() public {
    uint256 deployerPrivateKey = vm.envUint('DEPLOYER_CONTRACT_DEPLOYER_PRIVATE_KEY');

    string memory contractName = 'StartaleSmartAccount';
    string memory saltString = 'STARTALE_SMART_ACCOUNT_IMPLEMENTATION_V_1_0_0_200525_z2znQA2'; // todo: get it from env
    // for above salt the address would be 0x000000fca5d013e9e1d1c9f9f65ebc0c74f41d9b

    // Review
    bytes memory deployedBytecode = hex'';

    // Load environment variables

    // bytes memory constructorArgs = abi.encode(owner, entryPoint, signersAddr);

    // Concatenate bytecode + constructor arguments
    // bytes memory finalBytecode = abi.encodePacked(deployedBytecode, constructorArgs);

    // Deploy contract if needed
    // deployGeneric(deployerPrivateKey, saltString, finalBytecode, contractName);
  }

  function deployGeneric(
    uint256 deployerPrivateKey,
    string memory saltString,
    bytes memory finalBytecode,
    string memory contractName
  ) public {
    // Compute derived salt
    bytes32 derivedSalt = keccak256(abi.encodePacked(saltString));

    // Compute contract address before deployment
    address computedAddress = deployerInstance.addressOf(derivedSalt);

    console.log(string(abi.encodePacked(contractName, ' Computed Address:')), computedAddress);

    // Check if contract is already deployed
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(computedAddress)
    }

    if (codeSize == 0) {
      console.log(string(abi.encodePacked(contractName, ' not deployed, deploying now...')));
      deployContract(deployerPrivateKey, derivedSalt, finalBytecode, contractName, computedAddress);
    } else {
      console.log(string(abi.encodePacked(contractName, ' already deployed at:')), computedAddress);
    }
  }

  function deployContract(
    uint256 deployerPrivateKey,
    bytes32 derivedSalt,
    bytes memory finalBytecode,
    string memory contractName,
    address computedAddress
  ) internal {
    uint256 chainId = block.chainid;

    uint256 gasPrice = DEPLOYMENT_CHAIN_GAS_PRICES[chainId];
    require(gasPrice > 0, NoGasPriceSet());

    console.log('Using gas price:', gasPrice);

    // Deploy contract using deployer's private key
    vm.startBroadcast(deployerPrivateKey);
    (bool success,) = address(deployerInstance).call{gas: 5_000_000}(
      abi.encodeWithSignature('deploy(bytes32,bytes)', derivedSalt, finalBytecode)
    );
    vm.stopBroadcast();

    require(success, ContractDeploymentFailed());

    console.log(string(abi.encodePacked('Transaction success: ', contractName)));

    // Verify deployment by checking contract existence
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(computedAddress)
    }

    if (codeSize == 0) {
      console.log(string(abi.encodePacked('Invalid deployment of ', contractName)));
    } else {
      console.log(string(abi.encodePacked(contractName, ' Deployed Successfully at:')), computedAddress);
    }
  }
}
