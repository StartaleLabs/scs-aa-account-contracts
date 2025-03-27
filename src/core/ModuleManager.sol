// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
  IExecutor,
  IFallback,
  IHook,
  IModule,
  IPreValidationHookERC1271,
  IPreValidationHookERC4337,
  IValidator
} from '../interfaces/IERC7579Module.sol';

import {IModuleManagerEventsAndErrors} from '../interfaces/core/IModuleManagerEventsAndErrors.sol';
import {DataParserLib} from '../lib/DataParserLib.sol';
import {ExecutionLib} from '../lib/ExecutionLib.sol';
import {CALLTYPE_SINGLE, CALLTYPE_STATIC, CallType} from '../lib/ModeLib.sol';

import {EmergencyUninstall} from '../types/Structs.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ExcessivelySafeCall} from 'excessively-safe-call/ExcessivelySafeCall.sol';
import {SentinelListLib} from 'sentinellist/SentinelList.sol';

import {ECDSA} from 'solady/utils/ECDSA.sol';
import {EIP712} from 'solady/utils/EIP712.sol';
/// @title ModuleManager
/// @notice Manages Validator, Executor, Hook, and Fallback modules
/// @dev Implements SentinelList for managing modules via a linked list structure, adhering to ERC-7579.
/// Special thanks to the Biconomy team for https://github.com/bcnmy/nexus/ and ERC7579 reference implementation on which this implementation is highly based on.
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady

abstract contract ModuleManager is IModuleManagerEventsAndErrors {
  using SentinelListLib for SentinelListLib.SentinelList;
  using DataParserLib for bytes;
  using ExecutionLib for address;
  using ExcessivelySafeCall for address;
  using ECDSA for bytes32;
}
