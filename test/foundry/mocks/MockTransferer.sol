// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockTransferer {
  error TransferFailed();

  function transfer(address to, uint256 amount) public {
    // use transfer
    uint256 balance = address(this).balance;
    payable(to).transfer(amount);
    if (address(this).balance != balance - amount) {
      revert TransferFailed();
    }
  }
}
