// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC4337Account} from '../../../src/interfaces/IERC4337Account.sol';

import {
  IHook,
  IModule,
  IPreValidationHookERC1271,
  IPreValidationHookERC4337,
  IValidator
} from '../../../src/interfaces/IERC7579Module.sol';
import {IAccountConfig} from '../../../src/interfaces/core/IAccountConfig.sol';
import {IExecutionHelper} from '../../../src/interfaces/core/IExecutionHelper.sol';
import {IModuleManager} from '../../../src/interfaces/core/IModuleManager.sol';
import {Test} from 'forge-std/Test.sol';

// import {console} from 'forge-std/console.sol';

contract CalculateSelectors is Test {
  function setUp() public {}

  function test_calculateSelector() public {
    bytes4 selector1 = IERC4337Account.executeUserOp.selector;
    // console.log('executeUserOp');
    // console.logBytes4(selector1);

    bytes4 selector2 = IAccountConfig.supportsModule.selector;
    // console.log('supportsModule');
    // console.logBytes4(selector2);

    bytes4 selector3 = IAccountConfig.supportsExecutionMode.selector;
    // console.log('supportsExecutionMode');
    // console.logBytes4(selector3);

    bytes4 selector4 = IAccountConfig.accountId.selector;
    // console.log('accountId');
    // console.logBytes4(selector4);

    bytes4 selector5 = IExecutionHelper.execute.selector;
    // console.log('execute');
    // console.logBytes4(selector5);

    bytes4 selector6 = IExecutionHelper.executeFromExecutor.selector;
    // console.log('executeFromExecutor');
    // console.logBytes4(selector6);

    bytes4 selector7 = IModuleManager.installModule.selector;
    // console.log('installModule');
    // console.logBytes4(selector7);

    bytes4 selector8 = IModuleManager.uninstallModule.selector;
    // console.log('uninstallModule');
    // console.logBytes4(selector8);

    bytes4 selector9 = IModuleManager.isModuleInstalled.selector;
    // console.log('isModuleInstalled');
    // console.logBytes4(selector9);

    bytes4 selector10 = IModule.onInstall.selector;
    // console.log('onInstall');
    // console.logBytes4(selector10);

    bytes4 selector11 = IModule.onUninstall.selector;
    // console.log('onUninstall');
    // console.logBytes4(selector11);

    bytes4 selector12 = IModule.isModuleType.selector;
    // console.log('isModuleType');
    // console.logBytes4(selector12);

    bytes4 selector13 = IModule.isInitialized.selector;
    // console.log('isInitialized');
    // console.logBytes4(selector13);

    bytes4 selector14 = IPreValidationHookERC1271.preValidationHookERC1271.selector;
    // console.log('preValidationHookERC1271');
    // console.logBytes4(selector14);

    bytes4 selector15 = IPreValidationHookERC4337.preValidationHookERC4337.selector;
    // console.log('preValidationHookERC4337');
    // console.logBytes4(selector15);

    bytes4 selector16 = IValidator.validateUserOp.selector;
    // console.log('validateUserOp');
    // console.logBytes4(selector16);

    bytes4 selector17 = IValidator.isValidSignatureWithSender.selector;
    // console.log('isValidSignatureWithSender');
    // console.logBytes4(selector17);

    bytes4 selector18 = IHook.preCheck.selector;
    // console.log('preCheck');
    // console.logBytes4(selector18);

    bytes4 selector19 = IHook.postCheck.selector;
    // console.log('postCheck');
    // console.logBytes4(selector19);
  }
}
