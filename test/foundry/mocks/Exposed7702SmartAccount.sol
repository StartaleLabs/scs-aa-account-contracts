// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StartaleSmartAccount} from '../../../src/StartaleSmartAccount.sol';
import {IERC7579Account} from '../../../src/interfaces/IERC7579Account.sol';

interface IExposed7702SmartAccount is IERC7579Account {
  function amIERC7702() external view returns (bool);
}

contract Exposed7702SmartAccount is StartaleSmartAccount, IExposed7702SmartAccount {
  constructor(
    address anEntryPoint,
    address defaultValidator,
    bytes memory initData
  ) StartaleSmartAccount(anEntryPoint, defaultValidator, initData) {}

  function amIERC7702() external view returns (bool) {
    return _amIERC7702();
  }
}
