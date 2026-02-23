// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title IERC20
/// @notice Minimal ERC20 interface used by arbitrage execution and tests.
/// @dev This interface defines token interactions for transfer, allowance, and balance checks.
interface IERC20 {
    /// @notice Returns the total token supply.
    function totalSupply() external view returns (uint256);
    /// @notice Returns token balance for `account`.
    function balanceOf(address account) external view returns (uint256);
    /// @notice Returns remaining allowance from `owner` to `spender`.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Transfers `amount` tokens to `to`.
    function transfer(address to, uint256 amount) external returns (bool);
    /// @notice Approves `spender` for `amount`.
    function approve(address spender, uint256 amount) external returns (bool);
    /// @notice Transfers `amount` from `from` to `to`.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
