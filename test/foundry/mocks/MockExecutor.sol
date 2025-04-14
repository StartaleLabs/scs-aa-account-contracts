// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IExecutor, IModule} from '../../../src/interfaces/IERC7579Module.sol';

import {IStartaleSmartAccount} from '../../../src/interfaces/IStartaleSmartAccount.sol';

import {ExecutionLib} from '../../../src/lib/ExecutionLib.sol';
import {
  CALLTYPE_BATCH,
  CALLTYPE_DELEGATECALL,
  CALLTYPE_SINGLE,
  CallType,
  EXECTYPE_DEFAULT,
  EXECTYPE_TRY,
  ExecType,
  ExecutionMode,
  ModeLib
} from '../../../src/lib/ModeLib.sol';
import {MODE_DEFAULT, ModePayload} from '../../../src/lib/ModeLib.sol';
import {EncodedModuleTypes} from '../../../src/lib/ModuleTypeLib.sol';
import {MODULE_TYPE_EXECUTOR} from '../../../src/types/Constants.sol';
import '../../../src/types/Structs.sol';

contract MockExecutor is IExecutor {
  event ExecutorOnInstallCalled(bytes32 dataFirstWord);

  function onInstall(bytes calldata data) external override {
    if (data.length >= 0x20) {
      emit ExecutorOnInstallCalled(bytes32(data[0:32]));
    }
  }

  function onUninstall(bytes calldata data) external override {}

  function executeViaAccount(
    IStartaleSmartAccount account,
    address target,
    uint256 value,
    bytes calldata callData
  ) external returns (bytes[] memory returnData) {
    return account.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(target, value, callData));
  }

  function execDelegatecall(
    IStartaleSmartAccount account,
    bytes calldata callData
  ) external returns (bytes[] memory returnData) {
    return account.executeFromExecutor(
      ModeLib.encode(CALLTYPE_DELEGATECALL, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00)), callData
    );
  }

  function executeBatchViaAccount(
    IStartaleSmartAccount account,
    Execution[] calldata execs
  ) external returns (bytes[] memory returnData) {
    return account.executeFromExecutor(ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(execs));
  }

  function tryExecuteViaAccount(
    IStartaleSmartAccount account,
    address target,
    uint256 value,
    bytes calldata callData
  ) external returns (bytes[] memory returnData) {
    return account.executeFromExecutor(ModeLib.encodeTrySingle(), ExecutionLib.encodeSingle(target, value, callData));
  }

  function tryExecuteBatchViaAccount(
    IStartaleSmartAccount account,
    Execution[] calldata execs
  ) external returns (bytes[] memory returnData) {
    return account.executeFromExecutor(ModeLib.encodeTryBatch(), ExecutionLib.encodeBatch(execs));
  }

  function customExecuteViaAccount(
    ExecutionMode mode,
    IStartaleSmartAccount account,
    address target,
    uint256 value,
    bytes calldata callData
  ) external returns (bytes[] memory) {
    (CallType callType,) = ModeLib.decodeBasic(mode);
    bytes memory executionCallData;
    if (callType == CALLTYPE_SINGLE) {
      executionCallData = ExecutionLib.encodeSingle(target, value, callData);
      return account.executeFromExecutor(mode, executionCallData);
    } else if (callType == CALLTYPE_BATCH) {
      Execution[] memory execution = new Execution[](2);
      execution[0] = Execution(target, 0, callData);
      execution[1] = Execution(address(this), 0, executionCallData);
      executionCallData = ExecutionLib.encodeBatch(execution);
      return account.executeFromExecutor(mode, executionCallData);
    }
    return account.executeFromExecutor(mode, ExecutionLib.encodeSingle(target, value, callData));
  }

  function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
    return moduleTypeId == MODULE_TYPE_EXECUTOR;
  }

  function getModuleTypes() external view returns (EncodedModuleTypes) {}

  function isInitialized(address) external pure override returns (bool) {
    return false;
  }

  receive() external payable {}
}
