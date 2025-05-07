// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import './EventsAndErrors.sol';

// Necessary imports

// ==========================
// Utility Libraries
// ==========================

import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import 'solady/utils/ECDSA.sol';
import {EIP712} from 'solady/utils/EIP712.sol';

// ==========================
// Account Abstraction Imports
// ==========================

import {IEntryPoint} from '@account-abstraction/interfaces/IEntryPoint.sol';
import '@account-abstraction/interfaces/PackedUserOperation.sol';
import {EntryPoint} from 'account-abstraction/core/EntryPoint.sol';

// ==========================
// ModeLib Import
// ==========================

import '../../../src/lib/ExecutionLib.sol';
import '../../../src/lib/ModeLib.sol';
import './ModuleTypeLib.sol';

// ==========================
// Interface Imports
// ==========================
// import "../../../src/interfaces/core/IAccountConfig.sol";
// import "../../../src/interfaces/core/IModuleManager.sol";
// import "../../../src/interfaces/IERC7579Module.sol";
// import "../../../src/interfaces/core/IAllStorage.sol";
// import "../../../src/interfaces/IStartaleSmartAccount.sol";

// ==========================
// Contract Implementations
// ==========================
// import "../../../src/StartaleSmartAccount.sol";
// import "../../../src/factory/StartaleAccountFactory.sol";
// import "../../../src/factory/EOAOnboardingFactory.sol";
// import "./../../../src/modules/validators/ECDSAValidator.sol";
// import "../../../src/utils/Stakeable.sol";

// from foundry mocks if needed
// import "../../../src/mocks/ExposedStartaleSmartAccount.sol";

// ==========================
// Mock Contracts for Testing
// ==========================

// import { MockPaymaster } from "../../../contracts/mocks/MockPaymaster.sol";
// import { MockInvalidModule } from "./../../../contracts/mocks/MockInvalidModule.sol";
// import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
// import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import {MockValidator} from '../mocks/MockValidator.sol';
// import { MockHook } from "../../../contracts/mocks/MockHook.sol";
import {MockToken} from '../mocks/MockToken.sol';
// import { MockMultiModule } from "contracts/mocks/MockMultiModule.sol";
// import { MockRegistry } from "../../../contracts/mocks/MockRegistry.sol";
// import { MockSafe1271Caller } from "../../../contracts/mocks/MockSafe1271Caller.sol";
// import { MockPreValidationHook } from "../../../contracts/mocks/MockPreValidationHook.sol";

// import "../mocks/MockNFT.sol";

import '../mocks/Counter.sol';

// ==========================
// Additional Contract Imports
// ==========================

import './../../../src/utils/Bootstrap.sol';
import './BootstrapLib.sol';

// ==========================
// Sentinel List Helper
// ==========================
import {SentinelListLib} from 'sentinellist/SentinelList.sol';
import {SentinelListHelper} from 'sentinellist/SentinelListHelper.sol';

import {TestHelper} from './TestHelper.sol';

// Startale Account Testing Base

/// @title TestBase - Base contract for testing Startale smart account functionalities
/// @notice This contract inherits from TestHelper to provide common setup and utilities for Startale tests
abstract contract TestBase is TestHelper {
  /// @notice Modifier to check Paymaster balance before and after transaction
  /// @param paymaster The paymaster to check the balance for
  modifier checkPaymasterBalance(address paymaster) {
    uint256 balanceBefore = ENTRYPOINT.balanceOf(paymaster);
    _;
    uint256 balanceAfter = ENTRYPOINT.balanceOf(paymaster);
    assertLt(balanceAfter, balanceBefore, 'Paymaster deposit not used');
  }

  /// @notice Initializes the testing environment
  function init() internal virtual {
    setupTestEnvironment();
  }

  receive() external payable {}
}
