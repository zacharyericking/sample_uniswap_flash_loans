// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title ISwapRouter
/// @notice Minimal Uniswap V3 router interface needed for 1-hop exact-input swaps.
/// @dev Triangular execution performs this operation three times with different route legs.
interface ISwapRouter {
    /// @notice Input parameters for exact-input single-pool swap.
    struct ExactInputSingleParams {
        /// @notice Input token address.
        address tokenIn;
        /// @notice Output token address.
        address tokenOut;
        /// @notice Uniswap fee tier in hundredths of a bip.
        uint24 fee;
        /// @notice Recipient of output tokens.
        address recipient;
        /// @notice Last valid timestamp for swap execution.
        uint256 deadline;
        /// @notice Input amount to swap.
        uint256 amountIn;
        /// @notice Minimum output amount for slippage protection.
        uint256 amountOutMinimum;
        /// @notice Optional sqrt price limit, set to zero when unused.
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Executes exact input swap for a single pool.
    /// @param params Swap configuration and constraints.
    /// @return amountOut Output amount received from pool.
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}
