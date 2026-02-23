// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title ReentrancyGuard
/// @notice Single-entry lock for stateful external execution functions.
/// @dev Protects swap execution and signature processing against nested calls.
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private _status = 1;

    /// @notice Prevents nested entry into protected functions.
    /// @dev Restores state even when protected function body succeeds.
    modifier nonReentrant() {
        if (_status == 2) revert Reentrancy();
        _status = 2;
        _;
        _status = 1;
    }
}
