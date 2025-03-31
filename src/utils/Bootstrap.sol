// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ModuleManager} from '../core/ModuleManager.sol';
import {IModule} from '../interfaces/IERC7579Module.sol';
import {
  MODULE_TYPE_EXECUTOR, MODULE_TYPE_FALLBACK, MODULE_TYPE_HOOK, MODULE_TYPE_VALIDATOR
} from '../types/Constants.sol';

/// @title Bootstrap Configuration for Startale smart account
/// @notice Provides configuration and initialization.
/// @author Startale
/// Special thanks to the Biconomy team and ERC7579 reference implementation.
struct BootstrapConfig {
  address module;
  bytes data;
}

/// @title Bootstrap
/// @notice Manages the installation of modules into Smart Account using delegate calls.
contract Bootstrap is ModuleManager {
  constructor(address defaultValidator, bytes memory initData) ModuleManager(defaultValidator, initData) {}

  modifier _withInitSentinelLists() {
    _initSentinelLists();
    _;
  }

  /// @notice Initializes the account with the default validator.
  /// @dev Intended to be called by the Smart Account with a delegatecall.
  /// @dev Should we integrate 7484, The 7484 registry could be initialized via the `setRegistry` function on the Smart Account contract later if needed.
  /// @param data The initialization data for the default validator module.
  function initWithDefaultValidator(bytes calldata data) external payable {
    IModule(_DEFAULT_VALIDATOR).onInstall(data);
  }

  // ================================================
  // ===== DEFAULT VALIDATOR + OTHER MODULES =====
  // ================================================
  /// @notice Initializes the account with the default validator and other modules.
  /// @dev Intended to be called by the Smart Account with a delegatecall.
  /// @param defaultValidatorInitData The initialization data for the default validator module.
  /// @param executors The configuration array for executor modules.
  /// @param hook The configuration for the hook module.
  /// @param fallbacks The configuration array for fallback handler modules.
  function initNexusWithDefaultValidatorAndOtherModules(
    bytes calldata defaultValidatorInitData,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks
  ) external payable {
    _initWithDefaultValidatorAndOtherModules(defaultValidatorInitData, executors, hook, fallbacks);
  }

  function _initWithDefaultValidatorAndOtherModules(
    bytes calldata defaultValidatorInitData,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks
  ) internal _withInitSentinelLists {
    IModule(_DEFAULT_VALIDATOR).onInstall(defaultValidatorInitData);

    for (uint256 i = 0; i < executors.length; i++) {
      if (executors[i].module == address(0)) continue;
      _installExecutor(executors[i].module, executors[i].data);
      emit ModuleInstalled(MODULE_TYPE_EXECUTOR, executors[i].module);
    }

    // Initialize hook
    if (hook.module != address(0)) {
      _installHook(hook.module, hook.data);
      emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
    }

    // Initialize fallback handlers
    for (uint256 i = 0; i < fallbacks.length; i++) {
      if (fallbacks[i].module == address(0)) continue;
      _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
      emit ModuleInstalled(MODULE_TYPE_FALLBACK, fallbacks[i].module);
    }
  }

  // ================================================
  // ===== SINGLE VALIDATOR =====
  // ================================================
  /// @notice Initializes the Smart Account with a single validator.
  /// @dev Intended to be called by the starttale account with a delegatecall.
  /// @param validator The address of the validator module.
  /// @param data The initialization data for the validator module.
  function initWithSingleValidator(IModule validator, bytes calldata data) external payable {
    _initWithSingleValidator(validator, data);
  }

  function _initWithSingleValidator(IModule validator, bytes calldata data) internal _withInitSentinelLists {
    _installValidator(address(validator), data);
    emit ModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator));
  }

  // ================================================
  // ===== GENERALIZED FLOW =====
  // ================================================

  /// @notice Initializes the startale Smart Account with multiple modules.
  /// @dev Intended to be called by the Smart Account with a delegatecall.
  /// @param validators The configuration array for validator modules.
  /// @param executors The configuration array for executor modules.
  /// @param hook The configuration for the hook module.
  /// @param fallbacks The configuration array for fallback handler modules.
  function init(
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks
  ) external payable {
    _init(validators, executors, hook, fallbacks);
  }

  function _init(
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks
  ) internal _withInitSentinelLists {
    // Initialize validators
    for (uint256 i = 0; i < validators.length; i++) {
      _installValidator(validators[i].module, validators[i].data);
      emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
    }

    // Initialize executors
    for (uint256 i = 0; i < executors.length; i++) {
      if (executors[i].module == address(0)) continue;
      _installExecutor(executors[i].module, executors[i].data);
      emit ModuleInstalled(MODULE_TYPE_EXECUTOR, executors[i].module);
    }

    // Initialize fallback handlers
    for (uint256 i = 0; i < fallbacks.length; i++) {
      if (fallbacks[i].module == address(0)) continue;
      _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
      emit ModuleInstalled(MODULE_TYPE_FALLBACK, fallbacks[i].module);
    }

    // Initialize hook
    if (hook.module != address(0)) {
      _installHook(hook.module, hook.data);
      emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
    }
  }

  // ================================================
  // ===== SCOPED FLOW =====
  // ================================================

  /// @notice Initializes the Smart Account with a scoped set of modules.
  /// @dev Intended to be called by the startale smart account with a delegatecall.
  /// @param validators The configuration array for validator modules.
  /// @param hook The configuration for the hook module.
  function initScoped(BootstrapConfig[] calldata validators, BootstrapConfig calldata hook) external payable {
    _initScoped(validators, hook);
  }

  /// @notice Initializes the Smart account with a scoped set of modules.
  /// @dev Intended to be called by the startale smart account with a delegatecall.
  /// @param validators The configuration array for validator modules.
  /// @param hook The configuration for the hook module.
  function _initScoped(
    BootstrapConfig[] calldata validators,
    BootstrapConfig calldata hook
  ) internal _withInitSentinelLists {
    // Initialize validators
    for (uint256 i = 0; i < validators.length; i++) {
      _installValidator(validators[i].module, validators[i].data);
      emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
    }

    // Initialize hook
    if (hook.module != address(0)) {
      _installHook(hook.module, hook.data);
      emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
    }
  }

  // ================================================
  // ===== EXTERNAL VIEW HELPERS =====
  // ================================================

  /// @notice Prepares calldata for the init function.
  /// @param validators The configuration array for validator modules.
  /// @param executors The configuration array for executor modules.
  /// @param hook The configuration for the hook module.
  /// @param fallbacks The configuration array for fallback handler modules.
  /// @return initData The prepared calldata for init().
  function getInitNexusCalldata(
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks
  ) external view returns (bytes memory initData) {
    initData = abi.encode(address(this), abi.encodeCall(this.init, (validators, executors, hook, fallbacks)));
  }

  /// @notice Prepares calldata for the initScoped function.
  /// @param validators The configuration array for validator modules.
  /// @param hook The configuration for the hook module.
  /// @return initData The prepared calldata for initScoped.
  function getInitScopedCalldata(
    BootstrapConfig[] calldata validators,
    BootstrapConfig calldata hook
  ) external view returns (bytes memory initData) {
    initData = abi.encode(address(this), abi.encodeCall(this.initScoped, (validators, hook)));
  }

  /// @notice Prepares calldata for the initWithSingleValidator function.
  /// @param validator The configuration for the validator module.
  /// @return initData The prepared calldata for initWithSingleValidator.
  function getInitWithSingleValidatorCalldata(BootstrapConfig calldata validator)
    external
    view
    returns (bytes memory initData)
  {
    initData = abi.encode(
      address(this), abi.encodeCall(this.initWithSingleValidator, (IModule(validator.module), validator.data))
    );
  }

  /// @dev EIP712 domain name and version.
  function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
    name = 'StartaleAccountBootstrap';
    version = '0.0.1';
  }
}
