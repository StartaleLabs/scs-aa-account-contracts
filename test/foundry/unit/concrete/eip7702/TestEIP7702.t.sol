// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
  IHook, IPreValidationHookERC1271, IPreValidationHookERC4337
} from '../../../../../src/interfaces/IERC7579Module.sol';

import {IStartaleSmartAccount} from '../../../../../src/interfaces/IStartaleSmartAccount.sol';
import {IExecutionHelper} from '../../../../../src/interfaces/core/IExecutionHelper.sol';
import {MODE_VALIDATION, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337} from '../../../../../src/types/Constants.sol';
import {Exposed7702SmartAccount, IExposed7702SmartAccount} from '../../../mocks/Exposed7702SmartAccount.sol';
import {MockDelegateTarget} from '../../../mocks/MockDelegateTarget.sol';
import {MockExecutor} from '../../../mocks/MockExecutor.sol';

import {MockHook} from '../../../mocks/MockHook.sol';
import {MockPreValidationHook} from '../../../mocks/MockPreValidationHook.sol';
import {MockTarget} from '../../../mocks/MockTarget.sol';
import {MockTransferer} from '../../../mocks/MockTransferer.sol';
import '../../../utils/TestBase.sol';

contract TestEIP7702 is TestBase {
  using ECDSA for bytes32;

  MockDelegateTarget delegateTarget;
  MockTarget target;
  MockValidator public mockValidator;
  MockExecutor public mockExecutor;
  MockPreValidationHook public mockPreValidationHook;

  function setUp() public {
    setupTestEnvironment();
    delegateTarget = new MockDelegateTarget();
    target = new MockTarget();
    mockValidator = new MockValidator();
    mockExecutor = new MockExecutor();
    mockPreValidationHook = new MockPreValidationHook();
  }

  function _getInitData() internal view returns (bytes memory) {
    // Create config for initial modules
    BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(mockValidator), '');
    BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(mockExecutor), '');
    BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), '');
    BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(0), '');
    BootstrapPreValidationHookConfig[] memory preValidationHooks = BootstrapLib.createArrayPreValidationHookConfig(
      MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(mockPreValidationHook), ''
    );

    return abi.encode(
      address(BOOTSTRAPPER),
      abi.encodeCall(BOOTSTRAPPER.init, (validators, executors, hook, fallbacks, preValidationHooks))
    );
  }

  function _getSignature(uint256 eoaKey, PackedUserOperation memory userOp) internal view returns (bytes memory) {
    bytes32 hash = ENTRYPOINT.getUserOpHash(userOp);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, hash.toEthSignedMessageHash());
    return abi.encodePacked(r, s, v);
  }

  function test_execSingle() public returns (address) {
    // Create calldata for the account to execute
    bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);

    // Encode the call into the calldata for the userOp
    bytes memory userOpCalldata = abi.encodeCall(
      IExecutionHelper.execute,
      (ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(address(target), uint256(0), setValueOnTarget))
    );

    // Get the account, initcode and nonce
    uint256 eoaKey = uint256(8);
    address account = vm.addr(eoaKey);
    vm.deal(account, 100 ether);

    uint256 nonce = getNonce(account, MODE_VALIDATION, address(0), 0);

    // Create the userOp and add the data
    PackedUserOperation memory userOp = buildPackedUserOp(address(account), nonce);
    userOp.callData = userOpCalldata;

    userOp.signature = _getSignature(eoaKey, userOp);
    _doEIP7702(account);

    // Create userOps array
    PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    userOps[0] = userOp;

    // Send the userOp to the entrypoint
    ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

    // Assert that the value was set ie that execution was successful
    assertTrue(target.value() == 1337);
    return account;
  }

  function test_transfer_to_eip7702_account() public {
    MockTransferer transferer = new MockTransferer();
    vm.deal(address(transferer), 10 ether);

    // Get the account, initcode and nonce
    uint256 eoaKey = uint256(8);
    address account = vm.addr(eoaKey);
    _doEIP7702(account);

    transferer.transfer(account, 1 ether);
    assertEq(address(transferer).balance, 9 ether);
    assertEq(account.balance, 1 ether);
  }

  function test_initializeAndExecSingle() public returns (address) {
    // Get the account, initcode and nonce
    uint256 eoaKey = uint256(8);
    address account = vm.addr(eoaKey);
    vm.deal(account, 100 ether);

    // Create calldata for the account to execute
    bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);

    bytes memory initData = _getInitData();

    Execution[] memory executions = new Execution[](2);
    executions[0] = Execution({
      target: account,
      value: 0,
      callData: abi.encodeCall(IStartaleSmartAccount.initializeAccount, initData)
    });
    executions[1] = Execution({target: address(target), value: 0, callData: setValueOnTarget});

    // Encode the call into the calldata for the userOp
    bytes memory userOpCalldata =
      abi.encodeCall(IExecutionHelper.execute, (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions)));

    uint256 nonce = getNonce(account, MODE_VALIDATION, address(0), 0);

    // Create the userOp and add the data
    PackedUserOperation memory userOp = buildPackedUserOp(address(account), nonce);
    userOp.callData = userOpCalldata;

    userOp.signature = _getSignature(eoaKey, userOp);
    _doEIP7702(account);

    // Create userOps array
    PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    userOps[0] = userOp;

    // Send the userOp to the entrypoint
    ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

    // Assert that the value was set ie that execution was successful
    assertTrue(target.value() == 1337);
    return account;
  }

  function test_execBatch() public {
    // Create calldata for the account to execute
    bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1337);
    address target2 = address(0x420);
    uint256 target2Amount = 1 wei;

    // Create the executions
    Execution[] memory executions = new Execution[](2);
    executions[0] = Execution({target: address(target), value: 0, callData: setValueOnTarget});
    executions[1] = Execution({target: target2, value: target2Amount, callData: ''});

    // Encode the call into the calldata for the userOp
    bytes memory userOpCalldata =
      abi.encodeCall(IExecutionHelper.execute, (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(executions)));

    // Get the account, initcode and nonce
    uint256 eoaKey = uint256(8);
    address account = vm.addr(eoaKey);
    vm.deal(account, 100 ether);

    uint256 nonce = getNonce(account, MODE_VALIDATION, address(0), 0);

    // Create the userOp and add the data
    PackedUserOperation memory userOp = buildPackedUserOp(address(account), nonce);
    userOp.callData = userOpCalldata;
    userOp.callData = userOpCalldata;

    userOp.signature = _getSignature(eoaKey, userOp);
    _doEIP7702(account);

    // Create userOps array
    PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    userOps[0] = userOp;

    // Send the userOp to the entrypoint
    ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

    // Assert that the value was set ie that execution was successful
    assertTrue(target.value() == 1337);
    assertTrue(target2.balance == target2Amount);
  }

  function test_execSingleFromExecutor() public {
    address account = test_initializeAndExecSingle();

    bytes[] memory ret = mockExecutor.executeViaAccount(
      IStartaleSmartAccount(address(account)),
      address(target),
      0,
      abi.encodePacked(MockTarget.setValue.selector, uint256(1338))
    );

    assertEq(ret.length, 1);
    assertEq(abi.decode(ret[0], (uint256)), 1338);
  }

  function test_execBatchFromExecutor() public {
    address account = test_initializeAndExecSingle();

    bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, 1338);
    Execution[] memory executions = new Execution[](2);
    executions[0] = Execution({target: address(target), value: 0, callData: setValueOnTarget});
    executions[1] = Execution({target: address(target), value: 0, callData: setValueOnTarget});
    bytes[] memory ret =
      mockExecutor.executeBatchViaAccount({account: IStartaleSmartAccount(address(account)), execs: executions});

    assertEq(ret.length, 2);
    assertEq(abi.decode(ret[0], (uint256)), 1338);
  }

  function test_delegateCall() public {
    // Create calldata for the account to execute
    address valueTarget = makeAddr('valueTarget');
    uint256 value = 1 ether;
    bytes memory sendValue = abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

    // Encode the call into the calldata for the userOp
    bytes memory userOpCalldata = abi.encodeCall(
      IExecutionHelper.execute,
      (
        ModeLib.encode(CALLTYPE_DELEGATECALL, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00)),
        abi.encodePacked(address(delegateTarget), sendValue)
      )
    );

    // Get the account, initcode and nonce
    uint256 eoaKey = uint256(8);
    address account = vm.addr(eoaKey);
    vm.deal(account, 100 ether);

    uint256 nonce = getNonce(account, MODE_VALIDATION, address(0), 0);

    // Create the userOp and add the data
    PackedUserOperation memory userOp = buildPackedUserOp(address(account), nonce);
    userOp.callData = userOpCalldata;
    userOp.callData = userOpCalldata;

    userOp.signature = _getSignature(eoaKey, userOp);
    _doEIP7702(account);

    // Create userOps array
    PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    userOps[0] = userOp;

    // Send the userOp to the entrypoint
    ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

    // Assert that the value was set ie that execution was successful
    assertTrue(valueTarget.balance == value);
  }

  function test_delegateCall_fromExecutor() public {
    address account = test_initializeAndExecSingle();

    // Create calldata for the account to execute
    address valueTarget = makeAddr('valueTarget');
    uint256 value = 1 ether;
    bytes memory sendValue = abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

    // Execute the delegatecall via the executor
    mockExecutor.execDelegatecall(
      IStartaleSmartAccount(address(account)), abi.encodePacked(address(delegateTarget), sendValue)
    );

    // Assert that the value was set ie that execution was successful
    assertTrue(valueTarget.balance == value);
  }

  function test_amIERC7702_success() public {
    Exposed7702SmartAccount exposed7702 = new Exposed7702SmartAccount(
      address(ENTRYPOINT), address(DEFAULT_VALIDATOR_MODULE), abi.encodePacked(address(0xEeEe))
    );
    address eip7702account = address(0x7702acc7702acc7702acc7702acc);
    vm.etch(eip7702account, abi.encodePacked(bytes3(0xef0100), bytes20(address(exposed7702))));
    assertTrue(IExposed7702SmartAccount(eip7702account).amIERC7702());
  }

  function test_onRedelegation() public {
    address account = test_initializeAndExecSingle();
    MockHook mockHook = new MockHook();
    vm.startPrank(address(ENTRYPOINT));
    IStartaleSmartAccount(account).installModule(MODULE_TYPE_HOOK, address(mockHook), '');
    vm.stopPrank();
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ''));
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ''));
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ''));
    // storage is cleared
    vm.startPrank(address(account));
    IStartaleSmartAccount(account).onRedelegation();
    assertFalse(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ''));
    assertFalse(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ''));
    assertFalse(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ''));
    vm.stopPrank();

    // account is properly initialized to install modules again
    vm.startPrank(address(ENTRYPOINT));

    IStartaleSmartAccount(account).installModule(MODULE_TYPE_VALIDATOR, address(mockValidator), '');
    IStartaleSmartAccount(account).installModule(MODULE_TYPE_EXECUTOR, address(mockExecutor), '');
    IStartaleSmartAccount(account).installModule(MODULE_TYPE_HOOK, address(mockHook), '');

    vm.stopPrank();
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), ''));
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), ''));
    assertTrue(IStartaleSmartAccount(account).isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), ''));
  }
}
