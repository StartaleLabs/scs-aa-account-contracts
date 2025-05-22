// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProxyLib} from '../lib/ProxyLib.sol';
import {Bootstrap, BootstrapConfig} from '../utils/Bootstrap.sol';
import {Stakeable} from '../utils/Stakeable.sol';

/// @title EOAOnboardingFactory for Startale Smart Account
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using an ECDSA validator.
/// @author Startale
/// Special thanks to the Biconomy team for https://github.com/bcnmy/nexus/ on which this factory implementation is highly based on.
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract EOAOnboardingFactory is Stakeable {
  /// @notice Stores the implementation contract address used to create new account instances.
  /// @dev This address is set once upon deployment and cannot be changed afterwards.
  address public immutable ACCOUNT_IMPLEMENTATION;

  /// @notice Stores the ECDSA Validator module address.
  /// @dev This address is set once upon deployment and cannot be changed afterwards.
  address public immutable ECDSA_VALIDATOR;

  /// @notice Stores the Bootstrapper module address.
  /// @dev This address is set once upon deployment and cannot be changed afterwards.
  Bootstrap public immutable BOOTSTRAPPER;

  /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
  event AccountCreated(address indexed account, address indexed owner, uint256 indexed index);

  /// @notice Error thrown when a zero address is provided for the implementation, ECDSA validator, or bootstrapper.
  error ZeroAddressNotAllowed();

  /// @notice Error thrown when the implementation is not deployed.
  error ImplementationNotDeployed();

  /// @notice Constructor to set the immutable variables.
  /// @param implementation The address of the smart account implementation to be used for all deployments.
  /// @param factoryOwner The address of the factory owner.
  /// @param ecdsaValidator The address of the K1 Validator module to be used for all deployments.
  /// @param bootstrapper The address of the Bootstrapper module to be used for all deployments.
  constructor(
    address implementation,
    address factoryOwner,
    address ecdsaValidator,
    Bootstrap bootstrapper
  ) Stakeable(factoryOwner) {
    require(
      !(
        implementation == address(0) || ecdsaValidator == address(0) || address(bootstrapper) == address(0)
          || factoryOwner == address(0)
      ),
      ZeroAddressNotAllowed()
    );
    require(implementation.code.length > 0, ImplementationNotDeployed());
    ACCOUNT_IMPLEMENTATION = implementation;
    ECDSA_VALIDATOR = ecdsaValidator;
    BOOTSTRAPPER = bootstrapper;
  }

  /// @notice Creates a new Startale Smart Acount with a specific validator and initialization data.
  /// @param eoaOwner The address of the EOA owner.
  /// @param index The index of the Account(to deploy multiple with same auth config).
  /// @return The address of the newly created account.
  function createAccount(address eoaOwner, uint256 index) external payable returns (address payable) {
    // Compute the salt for deterministic deployment
    bytes32 salt = keccak256(abi.encodePacked(eoaOwner, index));

    bytes memory initData = abi.encode(
      address(BOOTSTRAPPER),
      abi.encodeCall(BOOTSTRAPPER.initWithSingleValidator, (ECDSA_VALIDATOR, abi.encodePacked(eoaOwner)))
    );

    // Deploy the Smart account using the ProxyLib
    (bool alreadyDeployed, address payable account) = ProxyLib.deployProxy(ACCOUNT_IMPLEMENTATION, salt, initData);
    if (!alreadyDeployed) {
      emit AccountCreated(account, eoaOwner, index);
    }
    return account;
  }

  /// @notice Computes the expected address of a Startale smart account contract using the factory's deterministic deployment algorithm.
  /// @param eoaOwner The address of the EOA owner.
  /// @param index The index of the the Account(to deploy multiple with same auth config).
  /// @return expectedAddress The expected address at which the smart account contract will be deployed if the provided parameters are used.
  function computeAccountAddress(
    address eoaOwner,
    uint256 index
  ) external view returns (address payable expectedAddress) {
    // Compute the salt for deterministic deployment
    bytes32 salt = keccak256(abi.encodePacked(eoaOwner, index));

    bytes memory initData = abi.encode(
      address(BOOTSTRAPPER),
      abi.encodeCall(BOOTSTRAPPER.initWithSingleValidator, (ECDSA_VALIDATOR, abi.encodePacked(eoaOwner)))
    );

    // Compute the predicted address using the ProxyLib
    return ProxyLib.predictProxyAddress(ACCOUNT_IMPLEMENTATION, salt, initData);
  }
}
