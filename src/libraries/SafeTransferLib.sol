// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { IERC20 } from "../interfaces/IERC20.sol";

/// @title SafeTransferLib
/// @notice ERC20 wrappers that tolerate standard and non-standard return conventions.
/// @dev Used by executor and rescue flows to make token I/O fail-closed.
library SafeTransferLib {
    error TransferFailed();
    error TransferFromFailed();
    error ApproveFailed();

    /// @notice Safely transfers tokens from the current contract to `to`.
    /// @dev Reverts when token call fails or returns `false`.
    /// @param token ERC20 token interface.
    /// @param to Recipient address.
    /// @param amount Transfer amount.
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    /// @notice Safely transfers tokens from `from` to `to`.
    /// @dev Reverts when token call fails or returns `false`.
    /// @param token ERC20 token interface.
    /// @param from Sender address.
    /// @param to Recipient address.
    /// @param amount Transfer amount.
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) = address(token)
            .call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFromFailed();
        }
    }

    /// @notice Safely sets allowance for `spender`.
    /// @dev Reverts when token call fails or returns `false`.
    /// @param token ERC20 token interface.
    /// @param spender Approved spender address.
    /// @param amount Allowance amount.
    function safeApprove(IERC20 token, address spender, uint256 amount) internal {
        (bool ok, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ApproveFailed();
        }
    }
}
