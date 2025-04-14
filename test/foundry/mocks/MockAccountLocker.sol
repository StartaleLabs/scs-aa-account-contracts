// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IHook} from '../../../src/interfaces/IERC7579Module.sol';
import {MODULE_TYPE_HOOK} from '../../../src/types/Constants.sol';

contract MockAccountLocker is IHook {
  mapping(address => mapping(address => uint256)) lockedAmount;

  function getLockedAmount(address account, address token) external view returns (uint256) {
    return lockedAmount[token][account];
  }

  function setLockedAmount(address account, address token, uint256 amount) external {
    lockedAmount[token][account] = amount;
  }

  function onInstall(bytes calldata data) external override {}

  function onUninstall(bytes calldata data) external override {}

  function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
    return moduleTypeId == MODULE_TYPE_HOOK;
  }

  function isInitialized(address smartAccount) external view override returns (bool) {}

  function preCheck(
    address msgSender,
    uint256 msgValue,
    bytes calldata msgData
  ) external override returns (bytes memory hookData) {}

  function postCheck(bytes calldata hookData) external override {}
}
