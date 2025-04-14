// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IModule} from '../../../src/interfaces/IERC7579Module.sol';
import {EncodedModuleTypes} from '../../../src/lib/ModuleTypeLib.sol';
import '../../../src/types/Constants.sol';

contract MockHook is IModule {
  event PreCheckCalled();
  event PostCheckCalled();
  event HookOnInstallCalled(bytes32 dataFirstWord);

  error PreCheckFailedError();

  uint256 public a;

  function onInstall(bytes calldata data) external override {
    if (data.length >= 0x20) {
      emit HookOnInstallCalled(bytes32(data[0:32]));
    }
  }

  function onUninstall(bytes calldata) external override {
    emit PostCheckCalled();
  }

  function preCheck(address sender, uint256 value, bytes calldata data) external returns (bytes memory) {
    emit PreCheckCalled();

    a++;

    // Add a condition to revert if the sender is the zero address or if the value is 1 ether for testing purposes
    if (value == 1 ether) {
      revert PreCheckFailedError();
    }

    return '';
  }

  function postCheck(bytes calldata hookData) external {
    hookData;
    emit PostCheckCalled();
  }

  function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
    return moduleTypeId == MODULE_TYPE_HOOK;
  }

  function isInitialized(address) external pure returns (bool) {
    return false;
  }

  function getA() external view returns (uint256) {
    return a;
  }

  function cleanA() external {
    a = 0;
  }
}
