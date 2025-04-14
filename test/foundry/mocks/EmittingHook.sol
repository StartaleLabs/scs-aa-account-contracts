// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IModule} from '../../../src/interfaces/IERC7579Module.sol';
import {EncodedModuleTypes} from '../../../src/lib/ModuleTypeLib.sol';
import '../../../src/types/Constants.sol';

contract EmittingHook is IModule {
  event PreCheckMsgData(bytes data);
  event PreCheckExtractedSelector(bytes4 selector);
  event PreCheckSender(address sender);
  event PreCheckValue(uint256 value);
  event HookOnInstallCalled(bytes32 dataFirstWord);
  event PostCheckCalled();

  function onInstall(bytes calldata data) external override {
    if (data.length >= 0x20) {
      emit HookOnInstallCalled(bytes32(data[0:32]));
    }
  }

  function onUninstall(bytes calldata) external override {
    emit PostCheckCalled();
  }

  function preCheck(address sender, uint256 value, bytes calldata data) external returns (bytes memory) {
    bytes4 selector = bytes4(data[0:4]);
    emit PreCheckExtractedSelector(selector);
    emit PreCheckMsgData(data);
    emit PreCheckSender(sender);
    emit PreCheckValue(value);

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
}
