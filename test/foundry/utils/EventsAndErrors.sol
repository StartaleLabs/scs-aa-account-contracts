// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract EventsAndErrors {
  // placeholder
  event ModuleInstalled(uint256 hookType, address module);
  event ModuleUninstalled(uint256 hookType, address module);
  event ModuleUpdated(uint256 hookType, address module);
  event ModuleUpgraded(uint256 hookType, address module);
  event ModuleDowngraded(uint256 hookType, address module);
  event ModuleRemoved(uint256 hookType, address module);
  event ModuleAdded(uint256 hookType, address module);
  event ModuleReplaced(uint256 hookType, address module);
}
