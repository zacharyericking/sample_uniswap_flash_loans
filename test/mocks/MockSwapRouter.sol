// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import {ISwapRouter} from "../../src/interfaces/ISwapRouter.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockSwapRouter is ISwapRouter {
    error UnknownRate();
    error MinOut();

    struct Rate {
        uint256 numerator;
        uint256 denominator;
    }

    mapping(bytes32 => Rate) public rates;

    function setRate(address tokenIn, address tokenOut, uint24 fee, uint256 n, uint256 d) external {
        require(n > 0 && d > 0, "BAD_RATE");
        rates[_key(tokenIn, tokenOut, fee)] = Rate({numerator: n, denominator: d});
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        Rate memory rate = rates[_key(params.tokenIn, params.tokenOut, params.fee)];
        if (rate.numerator == 0) revert UnknownRate();

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        amountOut = (params.amountIn * rate.numerator) / rate.denominator;
        if (amountOut < params.amountOutMinimum) revert MinOut();

        MockERC20(params.tokenOut).mint(params.recipient, amountOut);
    }

    function _key(address tokenIn, address tokenOut, uint24 fee) private pure returns (bytes32) {
        return keccak256(abi.encode(tokenIn, tokenOut, fee));
    }
}
