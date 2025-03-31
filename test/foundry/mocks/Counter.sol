// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Counter {
  error CounterRevertOperation();

  uint256 private _number;

  function incrementNumber() public {
    _number++;
  }

  function decrementNumber() public {
    _number--;
  }

  function getNumber() public view returns (uint256) {
    return _number;
  }

  function revertOperation() public pure {
    revert CounterRevertOperation();
  }
}
