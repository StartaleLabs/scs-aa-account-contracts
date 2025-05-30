// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// keccak256(abi.encode(uint256(keccak256("initializable.transient.startale.account")) - 1)) & ~bytes32(uint256(0xff));
bytes32 constant INIT_SLOT = 0x754fd8b321c4649cb777ae6fdce7e89e9cceaa31a4f639795c7807eb7f1a2700;

/// @title Initializable
/// @dev This library provides a way to set a transient flag on a contract to ensure that it is only initialized during the
/// constructor execution. This is useful to prevent a contract from being initialized multiple times.
library Initializable {
  /// @dev Thrown when an attempt to initialize an already initialized contract is made
  error NotInitializable();

  /// @dev Sets the initializable flag in the transient storage slot to true
  function setInitializable() internal {
    bytes32 slot = INIT_SLOT;
    assembly {
      tstore(slot, 0x01)
    }
  }

  /// @dev Checks if the initializable flag is set in the transient storage slot, reverts with NotInitializable if not
  function requireInitializable() internal view {
    bytes32 slot = INIT_SLOT;
    // Load the current value from the slot, revert if 0
    assembly {
      let isInitializable := tload(slot)
      if iszero(isInitializable) {
        mstore(0x0, 0xaed59595) // NotInitializable()
        revert(0x1c, 0x04)
      }
    }
  }
}
