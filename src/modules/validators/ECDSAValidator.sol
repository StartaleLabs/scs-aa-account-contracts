// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IValidator} from '../../interfaces/IERC7579Module.sol';

import {EnumerableSet} from '../../lib/EnumerableSet4337.sol';
import {
  ERC1271_INVALID,
  ERC1271_MAGICVALUE,
  MODULE_TYPE_HOOK,
  MODULE_TYPE_VALIDATOR,
  VALIDATION_FAILED,
  VALIDATION_SUCCESS
} from '../../types/Constants.sol';
import {PackedUserOperation} from '@account-abstraction/interfaces/PackedUserOperation.sol';
import {ERC7739Validator} from 'erc7739Validator/ERC7739Validator.sol';
import {ECDSA} from 'solady/utils/ECDSA.sol';

/// @title ECDSAValidator
/// @notice A validator module that uses ECDSA signatures for verifying user operations
/// @notice Any key created based on the K1 curve (secp256k1), a widely used ECDSA algorithm can be owner of Smart account via this module.
/// @notice Ideal for social logins, existing EOA wallets
/// @dev Implements secure ownership validation by checking signatures against registered
///      owners. This module supports ERC-7579 and ERC-4337 standards, ensuring only the
///      legitimate owner of a smart account can authorize transactions.
///      Implements ERC-7739
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
contract ECDSAValidator is IValidator, ERC7739Validator {
  using ECDSA for bytes32;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Errors
  /**
   * @notice Error thrown when no owner is provided during installation
   */
  error NoOwnerProvided();

  /**
   * @notice Error thrown when the module is already initialized
   */
  error ModuleAlreadyInitialized();

  /**
   * @notice Error thrown when the owner address is zero
   */
  error OwnerCannotBeZeroAddress();

  /**
   * @notice Error thrown when provided data has an invalid length
   */
  error InvalidDataLength();

  /**
   * @notice Error thrown when safe senders data has invalid length
   */
  error InvalidSafeSendersLength();

  // Events
  /**
   * @notice Emitted when an owner is registered for an account
   * @param account The smart account address
   * @param owner The owner address
   */
  event OwnerRegistered(address indexed account, address indexed owner);

  /**
   * @notice Emitted when an owner is removed for an account
   * @param account The smart account address
   */
  event OwnerRemoved(address indexed account);

  // Storage
  /**
   * @notice Mapping of smart account addresses to their respective owner addresses
   */
  mapping(address => address) internal smartAccountOwners;

  /**
   * @notice Set of addresses considered safe senders for each smart account
   */
  EnumerableSet.AddressSet private _safeSenders;

  /**
   * @notice Initialize the module with the given data
   * @param _data The data to initialize the module with (owner address + optional safe senders)
   */
  function onInstall(bytes calldata _data) external override {
    if (_data.length == 0) {
      revert NoOwnerProvided();
    }
    if (_isInitialized(msg.sender)) {
      revert ModuleAlreadyInitialized();
    }

    address owner = address(bytes20(_data[0:20]));
    if (owner == address(0)) {
      revert OwnerCannotBeZeroAddress();
    }

    smartAccountOwners[msg.sender] = owner;
    emit OwnerRegistered(msg.sender, owner);

    if (_data.length > 20) {
      _fillSafeSenders(_data[20:]);
    }
  }

  /**
   * @notice De-initialize the module when uninstalled
   */
  function onUninstall(bytes calldata) external override {
    if (!_isInitialized(msg.sender)) {
      revert NotInitialized(msg.sender);
    }

    delete smartAccountOwners[msg.sender];
    emit OwnerRemoved(msg.sender);
    _safeSenders.removeAll(msg.sender);
  }

  /**
   * @notice Adds a safe sender to the _safeSenders list for the smart account
   * @param _sender The address to add as a safe sender
   */
  function addSafeSender(address _sender) external {
    _safeSenders.add(msg.sender, _sender);
  }

  /**
   * @notice Removes a safe sender from the _safeSenders list for the smart account
   * @param _sender The address to remove as a safe sender
   */
  function removeSafeSender(address _sender) external {
    _safeSenders.remove(msg.sender, _sender);
  }

  /**
   * @notice Transfers ownership of the validator to a new owner
   * @param _newOwner The address of the new owner
   */
  function transferOwnership(address _newOwner) external {
    // Review: other checks on newOwner address
    if (_newOwner == address(0)) {
      revert OwnerCannotBeZeroAddress();
    }

    smartAccountOwners[msg.sender] = _newOwner;
    emit OwnerRegistered(msg.sender, _newOwner);
  }

  /**
   * @notice Validates a PackedUserOperation
   * @param _userOp UserOperation to be validated
   * @param _userOpHash Hash of the UserOperation to be validated
   * @return validationResult The result of the signature validation
   */
  function validateUserOp(
    PackedUserOperation calldata _userOp,
    bytes32 _userOpHash
  ) external view override returns (uint256) {
    return _validateSignatureForOwner(getOwner(_userOp.sender), _userOpHash, _userOp.signature)
      ? VALIDATION_SUCCESS
      : VALIDATION_FAILED;
  }

  /**
   * @notice Validates an ERC-1271 signature
   * @dev Implements signature malleability prevention
   * @param _sender The sender of the ERC-1271 call to the account
   * @param _hash The hash of the message
   * @param _signature The signature of the message
   * @return sigValidationResult The result of the signature validation
   */
  function isValidSignatureWithSender(
    address _sender,
    bytes32 _hash,
    bytes calldata _signature
  ) external view virtual override returns (bytes4) {
    return _erc1271IsValidSignatureWithSender(_sender, _hash, _erc1271UnwrapSignature(_signature));
  }

  /**
   * @notice ISessionValidator interface for smart session
   * @notice This function is meant to be used as a stateless validator's sig verification function,
   * where sig is provided along with an onwer to check algorithm and verify agaisnt each other.
   * @param _hash The hash of the data to validate
   * @param _sig The signature data
   * @param _data The data to validate against (owner address in this case)
   * @return validSig True if the signature is valid
   */
  function validateSignatureWithData(
    bytes32 _hash,
    bytes calldata _sig,
    bytes calldata _data
  ) external view returns (bool validSig) {
    if (_data.length != 20) revert InvalidDataLength();
    address owner = address(bytes20(_data[0:20]));
    return _validateSignatureForOwner(owner, _hash, _sig);
  }

  /**
   * @notice Checks if a module is initialized for a smart account
   * @param _smartAccount The address of the smart account
   * @return True if the module is initialized
   */
  function isInitialized(address _smartAccount) external view override returns (bool) {
    return _isInitialized(_smartAccount);
  }

  /**
   * @notice Checks if a sender is in the _safeSenders list for the smart account
   * @param _sender The address to check
   * @param _smartAccount The smart account address
   * @return True if the sender is a safe sender
   */
  function isSafeSender(address _sender, address _smartAccount) external view returns (bool) {
    return _safeSenders.contains(_smartAccount, _sender);
  }

  /**
   * @notice Get the owner of a smart account
   * @param _smartAccount The address of the smart account
   * @return The owner of the smart account
   */
  function getOwner(address _smartAccount) public view returns (address) {
    address owner = smartAccountOwners[_smartAccount];
    return owner == address(0) ? _smartAccount : owner;
  }

  /**
   * @notice Returns the name of the module
   * @return The name of the module
   */
  function name() external pure returns (string memory) {
    return 'ECDSAValidator';
  }

  /**
   * @notice Returns the version of the module
   * @return The version of the module
   */
  function version() external pure returns (string memory) {
    return '0.0.1';
  }

  /**
   * @notice Checks if the module is of the specified type
   * @param _typeId The type ID to check
   * @return True if the module is of the specified type
   */
  function isModuleType(uint256 _typeId) external pure returns (bool) {
    return _typeId == MODULE_TYPE_VALIDATOR;
  }

  /**
   * @notice Internal check if a module is initialized for a smart account
   * @param _smartAccount The address of the smart account
   * @return True if the module is initialized
   */
  function _isInitialized(address _smartAccount) internal view returns (bool) {
    return smartAccountOwners[_smartAccount] != address(0);
  }

  /**
   * @notice Returns whether the `hash` and `signature` are valid
   * @param _hash The hash of the data to validate
   * @param _signature The signature data
   * @return True if the signature is valid
   */
  function _erc1271IsValidSignatureNowCalldata(
    bytes32 _hash,
    bytes calldata _signature
  ) internal view override returns (bool) {
    // Call custom internal function to validate the signature against credentials
    return _validateSignatureForOwner(getOwner(msg.sender), _hash, _signature);
  }

  /**
   * @notice Returns whether the `sender` is considered safe
   * @param _sender The sender address to check
   * @return True if the sender is considered safe
   */
  function _erc1271CallerIsSafe(address _sender) internal view virtual override returns (bool) {
    return (
      _sender == 0x000000000000D9ECebf3C23529de49815Dac1c4c // MulticallerWithSigner
        || _sender == msg.sender // Smart Account. Assume smart account never sends non safe eip-712 struct
        || _safeSenders.contains(msg.sender, _sender)
    ); // Check if sender is in _safeSenders for the Smart Account
  }

  /**
   * @notice Validates a signature for an owner
   * @param _owner The address of the owner
   * @param _hash The hash of the data to validate
   * @param _signature The signature data
   * @return True if the signature is valid
   */
  function _validateSignatureForOwner(
    address _owner,
    bytes32 _hash,
    bytes calldata _signature
  ) internal view returns (bool) {
    // Verify signer - owner can not be zero address in this contract
    if (_recoverSigner(_hash, _signature) == _owner) {
      return true;
    }

    if (_recoverSigner(_hash.toEthSignedMessageHash(), _signature) == _owner) {
      return true;
    }

    return false;
  }

  /**
   * @notice Recovers the signer from a signature
   * @param _hash The hash of the data to validate
   * @param _signature The signature data
   * @return The recovered signer address
   */
  function _recoverSigner(bytes32 _hash, bytes calldata _signature) internal view returns (address) {
    // Use recoverCalldata which reverts on invalid signature, preventing address(0) bypass.
    return _hash.recoverCalldata(_signature);
  }

  /**
   * @notice Fills the _safeSenders list from the given data
   * @param _data The data containing safe sender addresses
   */
  function _fillSafeSenders(bytes calldata _data) private {
    if (_data.length % 20 != 0) revert InvalidSafeSendersLength();

    for (uint256 i; i < _data.length / 20; i++) {
      _safeSenders.add(msg.sender, address(bytes20(_data[20 * i:20 * (i + 1)])));
    }
  }
}
