// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import '../../../../../src/factory/EOAOnboardingFactory.sol';

import '../../../../../src/interfaces/IStartaleSmartAccount.sol';
import {IModuleManager} from '../../../../../src/interfaces/core/IModuleManager.sol';
import {AccountProxy} from '../../../../../src/utils/AccountProxy.sol';
import '../../../../../src/utils/Bootstrap.sol';
import '../../../utils/TestBase.sol';

import {Vm} from 'forge-std/Vm.sol';

/// @title TestK1ValidatorFactory_Deployments
/// @notice Tests for deploying accounts using the K1ValidatorFactory and various methods.
contract TestEOAOnboardingFactory_Deployments is TestBase {
  Vm.Wallet public user;
  bytes initData;
  EOAOnboardingFactory public validatorFactory;
  Bootstrap public bootstrapper;

  /// @notice Sets up the testing environment.
  function setUp() public {
    init();
    user = newWallet('user');
    vm.deal(user.addr, 1 ether);
    initData = abi.encodePacked(user.addr);
    bootstrapper = new Bootstrap(address(DEFAULT_VALIDATOR_MODULE), abi.encodePacked(address(0xeEeEeEeE)));
    validatorFactory = new EOAOnboardingFactory(
      address(ACCOUNT_IMPLEMENTATION), address(FACTORY_OWNER.addr), address(VALIDATOR_MODULE), bootstrapper
    );
  }

  /// @notice Tests if the constructor correctly initializes the factory with the given implementation, K1 Validator, and Bootstrapper addresses.
  function test_ConstructorInitializesFactory() public {
    address implementation = address(ACCOUNT_IMPLEMENTATION);
    address k1Validator = address(0x456);
    Bootstrap bootstrapperInstance =
      new Bootstrap(address(DEFAULT_VALIDATOR_MODULE), abi.encodePacked(address(0xeEeEeEeE)));
    EOAOnboardingFactory factory =
      new EOAOnboardingFactory(implementation, FACTORY_OWNER.addr, k1Validator, bootstrapperInstance);

    // Verify the implementation address is set correctly
    assertEq(factory.ACCOUNT_IMPLEMENTATION(), implementation, 'Implementation address mismatch');

    // Verify the K1 Validator address is set correctly
    assertEq(factory.ECDSA_VALIDATOR(), k1Validator, 'K1 Validator address mismatch');

    // Verify the bootstrapper address is set correctly
    assertEq(address(factory.BOOTSTRAPPER()), address(bootstrapperInstance), 'Bootstrapper address mismatch');

    // Ensure the factory contract is deployed and is a valid contract
    assertTrue(isContract(address(factory)), 'Factory should be a contract');
  }

  /// @notice Tests that the constructor can take a zero address for the registry.
  function test_ConstructorInitializesWithRegistryAddressZero() public {
    address k1Validator = address(0x456);
    Bootstrap bootstrapperInstance =
      new Bootstrap(address(DEFAULT_VALIDATOR_MODULE), abi.encodePacked(address(0xeEeEeEeE)));
    EOAOnboardingFactory factory =
      new EOAOnboardingFactory(address(ACCOUNT_IMPLEMENTATION), FACTORY_OWNER.addr, k1Validator, bootstrapperInstance);

    // Verify the implementation address is set correctly
    assertEq(factory.ACCOUNT_IMPLEMENTATION(), address(ACCOUNT_IMPLEMENTATION), 'Implementation address mismatch');

    // Verify the K1 Validator address is set correctly
    assertEq(factory.ECDSA_VALIDATOR(), k1Validator, 'K1 Validator address mismatch');

    // Verify the bootstrapper address is set correctly
    assertEq(address(factory.BOOTSTRAPPER()), address(bootstrapperInstance), 'Bootstrapper address mismatch');

    // Ensure the factory contract is deployed and is a valid contract
    assertTrue(isContract(address(factory)), 'Factory should be a contract');
  }

  /// @notice Tests that the constructor reverts if the implementation address is zero.
  function test_Constructor_RevertIf_ImplementationIsZero() public {
    address zeroAddress = address(0);

    // Expect the contract deployment to revert with the correct error message
    vm.expectRevert(ZeroAddressNotAllowed.selector);

    // Try deploying the K1ValidatorFactory with an implementation address of zero
    new EOAOnboardingFactory(zeroAddress, address(this), address(VALIDATOR_MODULE), bootstrapper);
  }

  /// @notice Tests that the constructor reverts if the factory owner address is zero.
  function test_Constructor_RevertIf_FactoryOwnerIsZero() public {
    address zeroAddress = address(0);

    // Expect the contract deployment to revert with the correct error message
    vm.expectRevert(ZeroAddressNotAllowed.selector);

    // Try deploying the K1ValidatorFactory with an implementation address of zero
    new EOAOnboardingFactory(address(this), zeroAddress, address(VALIDATOR_MODULE), bootstrapper);
  }

  /// @notice Tests that the constructor reverts if the K1 Validator address is zero.
  function test_Constructor_RevertIf_K1ValidatorIsZero() public {
    address zeroAddress = address(0);

    // Expect the contract deployment to revert with the correct error message
    vm.expectRevert(ZeroAddressNotAllowed.selector);

    // Try deploying the K1ValidatorFactory with a K1 Validator address of zero
    new EOAOnboardingFactory(address(this), address(ACCOUNT_IMPLEMENTATION), zeroAddress, bootstrapper);
  }

  /// @notice Tests that the constructor reverts if the Bootstrapper address is zero.
  function test_Constructor_RevertIf_BootstrapperIsZero() public {
    Bootstrap zeroBootstrapper = Bootstrap(payable(0));

    // Expect the contract deployment to revert with the correct error message
    vm.expectRevert(ZeroAddressNotAllowed.selector);

    // Try deploying the K1ValidatorFactory with a Bootstrapper address of zero
    new EOAOnboardingFactory(
      address(this), address(ACCOUNT_IMPLEMENTATION), address(VALIDATOR_MODULE), zeroBootstrapper
    );
  }

  /// @notice Tests deploying an account using the factory directly.
  function test_DeployAccount_EOAOnboardingFactory_CreateAccount() public payable {
    uint256 index = 0;
    address expectedOwner = user.addr;

    address payable expectedAddress = validatorFactory.computeAccountAddress(expectedOwner, index);

    address payable deployedAccountAddress = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index);

    // Validate that the account was deployed correctly
    assertEq(deployedAccountAddress, expectedAddress, 'Deployed account address mismatch');

    assertEq(
      IModuleManager(deployedAccountAddress).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ''),
      true,
      'Validator should be installed'
    );
  }

  /// @notice Tests that computing the account address returns the expected address.
  function test_ComputeAccountAddress() public {
    uint256 index = 0;
    address expectedOwner = user.addr;

    address payable expectedAddress = validatorFactory.computeAccountAddress(expectedOwner, index);

    // Deploy the account to compare the address
    address payable deployedAccountAddress = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index);

    assertEq(deployedAccountAddress, expectedAddress, 'Computed address mismatch');
  }

  /// @notice Tests that creating an account with the same owner and index results in the same address.
  function test_CreateAccount_SameOwnerAndIndex() public payable {
    uint256 index = 0;
    address expectedOwner = user.addr;

    // Create the first account with the given owner and index
    address payable firstAccountAddress = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index);

    address payable secondAccountAddress = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index);

    assertEq(firstAccountAddress.balance, 2 ether, 'Account balance should be 2 ether');
    assertEq(firstAccountAddress, secondAccountAddress, 'Account addresses should be same');
  }

  /// @notice Tests that creating accounts with different indexes results in different addresses.
  function test_CreateAccount_DifferentIndexes() public payable {
    uint256 index0 = 0;
    uint256 index1 = 1;
    address expectedOwner = user.addr;

    address payable accountAddress0 = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index0);
    address payable accountAddress1 = validatorFactory.createAccount{value: 1 ether}(expectedOwner, index1);

    assertTrue(accountAddress0 != accountAddress1, 'Accounts with different indexes should have different addresses');
  }

  /// @notice Tests that the computed address matches the manually computed address using keccak256.
  function test_ComputeAccountAddress_MatchesManualComputation() public {
    address eoaOwner = user.addr;
    uint256 index = 1;

    // Compute the actual salt manually using keccak256
    bytes32 manualSalt = keccak256(abi.encodePacked(eoaOwner, index));

    // Get the initialization data for the smart account
    bytes memory _initData = abi.encode(
      address(validatorFactory.BOOTSTRAPPER()),
      abi.encodeCall(
        validatorFactory.BOOTSTRAPPER().initWithSingleValidator,
        (validatorFactory.ECDSA_VALIDATOR(), abi.encodePacked(eoaOwner))
      )
    );

    address expectedAddress = payable(
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                address(validatorFactory),
                manualSalt,
                keccak256(
                  abi.encodePacked(
                    type(AccountProxy).creationCode,
                    abi.encode(
                      validatorFactory.ACCOUNT_IMPLEMENTATION(),
                      abi.encodeCall(IStartaleSmartAccount.initializeAccount, _initData)
                    )
                  )
                )
              )
            )
          )
        )
      )
    );

    address computedAddress = validatorFactory.computeAccountAddress(eoaOwner, index);

    assertEq(expectedAddress, computedAddress, 'Computed address does not match manually computed address');
  }
}
