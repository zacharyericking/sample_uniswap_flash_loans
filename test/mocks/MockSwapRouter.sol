// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { ISwapRouter } from "../../src/interfaces/ISwapRouter.sol";
import { IERC20 } from "../../src/interfaces/IERC20.sol";
import { MockERC20 } from "./MockERC20.sol";

/// @title MockSwapRouter
/// @notice Deterministic Uniswap-like router mock for unit and integration tests.
/// @dev Converts input to output via configured rational rates and enforces min out checks.
contract MockSwapRouter is ISwapRouter {
    error UnknownRate();
    error MinOut();
    error InvalidRate();
    error InvalidParams();

    struct Rate {
        uint256 numerator;
        uint256 denominator;
    }

    mapping(bytes32 => Rate) public rates;

    /// @notice Configures deterministic rate for a token pair and fee tier.
    /// @param tokenIn Input token address.
    /// @param tokenOut Output token address.
    /// @param fee Fee tier key.
    /// @param n Rate numerator.
    /// @param d Rate denominator.
    function setRate(address tokenIn, address tokenOut, uint24 fee, uint256 n, uint256 d) external {
        if (tokenIn == address(0) || tokenOut == address(0) || fee == 0 || n == 0 || d == 0) {
            revert InvalidRate();
        }
        rates[_key(tokenIn, tokenOut, fee)] = Rate({ numerator: n, denominator: d });
    }

    /// @notice Executes deterministic exact-input conversion for configured rate.
    /// @param params Swap parameters.
    /// @return amountOut Computed output amount.
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        if (
            params.tokenIn == address(0) || params.tokenOut == address(0)
                || params.recipient == address(0) || params.fee == 0 || params.amountIn == 0
        ) {
            revert InvalidParams();
        }
        Rate memory rate = rates[_key(params.tokenIn, params.tokenOut, params.fee)];
        if (rate.numerator == 0) revert UnknownRate();

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        amountOut = (params.amountIn * rate.numerator) / rate.denominator;
        if (amountOut < params.amountOutMinimum) revert MinOut();

        MockERC20(params.tokenOut).mint(params.recipient, amountOut);
    }

    /// @notice Computes internal mapping key for rate lookup.
    /// @param tokenIn Input token.
    /// @param tokenOut Output token.
    /// @param fee Fee tier.
    /// @return Hash key used in `rates`.
    function _key(address tokenIn, address tokenOut, uint24 fee) private pure returns (bytes32) {
        return keccak256(abi.encode(tokenIn, tokenOut, fee));
    }
}
