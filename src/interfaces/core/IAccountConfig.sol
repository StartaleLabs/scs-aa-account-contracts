// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ExecutionMode} from '../../lib/ModeLib.sol';

/// @title ERC-7579 Account Configuration Interface
/// @notice Interface for querying and verifying configurations of Smart Accounts compliant with ERC-7579.
/// @dev Provides methods to check supported execution modes and module types for Smart Accounts.

interface IAccountConfig {
  /// @notice Returns the account ID in a structured format: "vendorname.accountname.semver"
  /// @return accountImplementationId The account ID of the smart account
  function accountId() external view returns (string memory accountImplementationId);

  /// @notice Checks if the account supports a certain execution mode.
  /// @param encodedMode The encoded mode to verify.
  /// @return supported True if the account supports the mode, false otherwise.
  function supportsExecutionMode(ExecutionMode encodedMode) external view returns (bool supported);

  /// @notice Checks if the account supports a specific module type.
  /// @param moduleTypeId The module type ID to verify.
  /// @return supported True if the account supports the module type, false otherwise.
  function supportsModule(uint256 moduleTypeId) external view returns (bool supported);
}
