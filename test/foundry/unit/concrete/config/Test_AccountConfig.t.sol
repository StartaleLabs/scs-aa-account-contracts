// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {TestBase} from '../../../utils/TestBase.sol';

/// @title Test suite for checking account ID in AccountConfig
contract TestAccountConfig_AccountId is TestBase {
  /// @notice Initialize the testing environment
  /// @notice Initialize the testing environment
  function setUp() public {
    setupPredefinedWallets();
    deployTestContracts();
  }

  /// @notice Tests if the account ID returns the expected value
  function test_WhenCheckingTheAccountID() external {
    string memory expected = 'startale.smart-account.0.0.1';
    assertEq(ACCOUNT_IMPLEMENTATION.accountId(), expected, 'AccountConfig should return the expected account ID.');
  }
}
