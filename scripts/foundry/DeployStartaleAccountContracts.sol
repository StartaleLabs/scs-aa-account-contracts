// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {StartaleSmartAccount} from '../../src/StartaleSmartAccount.sol';

import {EOAOnboardingFactory} from '../../src/factory/EOAOnboardingFactory.sol';
import {ECDSAValidator} from '../../src/modules/validators/ECDSAValidator.sol';
import {Bootstrap} from '../../src/utils/Bootstrap.sol';
import {Script, console} from 'forge-std/Script.sol';

contract DeployStartaleAccountContracts is Script {
  address entryPoint;

  function setUp() public {
    // EntryPoint v0.7 address
    entryPoint = vm.parseAddress('0x0000000071727De22E5E9d8BAf0edAc6f37da032');
  }

  // WIP
  function run() public {
    // address owner = vm.envAddress("FACTORY_OWNER");
    // uint256 salt = vm.envUint("SALT");
    vm.startBroadcast();
    // StartaleSmartAccount sa = new StartaleSmartAccount{salt: bytes32(_salt)}(

    // );
    // console.log("Startale Smart Account Contract deployed at ", address(sa));
    vm.stopBroadcast();
  }
}
