// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BootstrapConfig, BootstrapPreValidationHookConfig} from '../../../src/utils/Bootstrap.sol';

/// @title Bootstrap Configuration Library
/// @notice Provides utility functions to create and manage BootstrapConfig structures.
/// Special thanks to the Biconomy team for https://github.com/bcnmy/nexus/ and ERC7579 reference implementation on which this implementation is highly based on.
library BootstrapLib {
  error LengthMismatch();
  /// @notice Creates a single BootstrapConfig structure.
  /// @param module The address of the module.
  /// @param data The initialization data for the module.
  /// @return config A BootstrapConfig structure containing the module and its data.

  function createSingleConfig(address module, bytes memory data) internal pure returns (BootstrapConfig memory config) {
    config.module = module;
    config.data = data;
  }

  /// @notice Creates an array with a single BootstrapConfig structure.
  /// @param module The address of the module.
  /// @param data The initialization data for the module.
  /// @return config An array containing a single BootstrapConfig structure.
  function createArrayConfig(address module, bytes memory data) internal pure returns (BootstrapConfig[] memory config) {
    config = new BootstrapConfig[](1);
    config[0].module = module;
    config[0].data = data;
  }

  /// @notice Creates an array with a single BootstrapPreValidationHookConfig structure.
  /// @param hookType The type of the pre-validation hook.
  /// @param module The address of the module.
  /// @param data The initialization data for the module.
  /// @return config An array containing a single BootstrapPreValidationHookConfig structure.
  function createArrayPreValidationHookConfig(
    uint256 hookType,
    address module,
    bytes memory data
  ) internal pure returns (BootstrapPreValidationHookConfig[] memory config) {
    config = new BootstrapPreValidationHookConfig[](1);
    config[0].hookType = hookType;
    config[0].module = module;
    config[0].data = data;
  }

  /// @notice Creates an array of BootstrapConfig structures.
  /// @param modules An array of module addresses.
  /// @param datas An array of initialization data for each module.
  /// @return configs An array of BootstrapConfig structures.
  function createMultipleConfigs(
    address[] memory modules,
    bytes[] memory datas
  ) internal pure returns (BootstrapConfig[] memory configs) {
    if (modules.length != datas.length) revert LengthMismatch();
    configs = new BootstrapConfig[](modules.length);

    for (uint256 i = 0; i < modules.length; i++) {
      configs[i] = createSingleConfig(modules[i], datas[i]);
    }
  }
}
