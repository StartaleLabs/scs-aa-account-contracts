// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

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

/// @title Bootstrap Pre-Validation Hook Configuration
/// @notice Provides configuration for pre-validation hooks.
struct BootstrapPreValidationHookConfig {
  uint256 hookType;
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
  /// @param validators The configuration array for validator modules.
  /// @param executors The configuration array for executor modules.
  /// @param hook The configuration for the hook module.
  /// @param fallbacks The configuration array for fallback handler modules.
  function initWithDefaultValidatorAndOtherModules(
    bytes calldata defaultValidatorInitData,
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks,
    BootstrapPreValidationHookConfig[] calldata preValidationHooks
  ) external payable {
    _initWithDefaultValidatorAndOtherModules(
      defaultValidatorInitData, validators, executors, hook, fallbacks, preValidationHooks
    );
  }

  function _initWithDefaultValidatorAndOtherModules(
    bytes calldata defaultValidatorInitData,
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks,
    BootstrapPreValidationHookConfig[] calldata preValidationHooks
  ) internal _withInitSentinelLists {
    IModule(_DEFAULT_VALIDATOR).onInstall(defaultValidatorInitData);

    // Install multiple validators other than the default validator
    for (uint256 i; i < validators.length; i++) {
      if (validators[i].module == address(0)) continue;
      _installValidator(validators[i].module, validators[i].data);
      emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
    }

    // Install multiple executors
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

    // Initialize pre-validation hooks
    for (uint256 i; i < preValidationHooks.length; i++) {
      if (preValidationHooks[i].module == address(0)) continue;
      _installPreValidationHook(
        preValidationHooks[i].hookType, preValidationHooks[i].module, preValidationHooks[i].data
      );
      emit ModuleInstalled(preValidationHooks[i].hookType, preValidationHooks[i].module);
    }
  }

  // ================================================
  // ===== SINGLE VALIDATOR =====
  // ================================================
  /// @notice Initializes the Smart Account with a single validator.
  /// @dev Intended to be called by the starttale account with a delegatecall.
  /// @param validator The address of the validator module. Should not be the default validator.
  /// @param data The initialization data for the validator module.
  function initWithSingleValidator(address validator, bytes calldata data) external payable {
    _initWithSingleValidator(validator, data);
  }

  function _initWithSingleValidator(address validator, bytes calldata data) internal _withInitSentinelLists {
    _installValidator(address(validator), data);
    emit ModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator));
  }

  // ================================================
  // ===== GENERALIZED FLOW =====
  // ================================================

  /// @notice Initializes the startale Smart Account with multiple modules.
  /// @dev Intended to be called by the Smart Account with a delegatecall.
  /// @param validators The configuration array for validator modules. Should not include the default validator.
  /// @param executors The configuration array for executor modules.
  /// @param hook The configuration for the hook module.
  /// @param fallbacks The configuration array for fallback handler modules.
  function init(
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks,
    BootstrapPreValidationHookConfig[] calldata preValidationHooks
  ) external payable {
    _init(validators, executors, hook, fallbacks, preValidationHooks);
  }

  function _init(
    BootstrapConfig[] calldata validators,
    BootstrapConfig[] calldata executors,
    BootstrapConfig calldata hook,
    BootstrapConfig[] calldata fallbacks,
    BootstrapPreValidationHookConfig[] calldata preValidationHooks
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

    // Initialize pre-validation hooks
    for (uint256 i = 0; i < preValidationHooks.length; i++) {
      if (preValidationHooks[i].module == address(0)) continue;
      _installPreValidationHook(
        preValidationHooks[i].hookType, preValidationHooks[i].module, preValidationHooks[i].data
      );
      emit ModuleInstalled(preValidationHooks[i].hookType, preValidationHooks[i].module);
    }
  }

  // ================================================
  // ===== SCOPED FLOW =====
  // ================================================

  /// @notice Initializes the Smart Account with a scoped set of modules.
  /// @dev Intended to be called by the startale smart account with a delegatecall.
  /// @param validators The configuration array for validator modules. Should not be the default validator.
  /// @param hook The configuration for the hook module.
  function initScoped(BootstrapConfig[] calldata validators, BootstrapConfig calldata hook) external payable {
    _initScoped(validators, hook);
  }

  /// @notice Initializes the Smart account with a scoped set of modules.
  /// @dev Intended to be called by the startale smart account with a delegatecall.
  /// @param validators The configuration array for validator modules. Should not be the default validator.
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

  /// @dev EIP712 domain name and version.
  function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
    name = 'StartaleAccountBootstrap';
    version = '1.0.0';
  }

  // required implementations. Are not used.
  function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable override {
    // do nothing
  }

  function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable override {
    // do nothing
  }

  function isModuleInstalled(
    uint256 moduleTypeId,
    address module,
    bytes calldata additionalContext
  ) external view override returns (bool installed) {
    return false;
  }
}
