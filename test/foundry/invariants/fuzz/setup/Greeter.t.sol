// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {CommonBase} from 'forge-std/Base.sol';
import {Greeter, IERC20} from 'src/Greeter.sol';

contract GreeterSetup is CommonBase {
  Greeter internal _targetContract;

  constructor() {
    _targetContract = new Greeter('a', IERC20(address(1)));
  }
}
