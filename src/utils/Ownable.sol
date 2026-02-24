// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title Ownable
/// @notice Minimal ownership primitive for privileged administrative operations.
/// @dev Shared by supervisor and executor modules to centralize privileged control checks.
abstract contract Ownable {
    error Unauthorized();
    error ZeroAddress();

    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @notice Initializes the owner used by `onlyOwner` checks.
    /// @dev Reverts on zero address to prevent permanently unowned deployments.
    /// @param initialOwner Address granted initial administrative authority.
    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert ZeroAddress();
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    /// @notice Transfers ownership to a new administrative address.
    /// @dev This function secures module-level governance by rotating privileged control.
    /// @param newOwner New owner address authorized for future admin actions.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
