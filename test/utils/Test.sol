// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title Vm
/// @notice Minimal Foundry cheatcode interface for this repository's tests.
interface Vm {
    /// @notice Derives address from private key.
    function addr(uint256 privateKey) external returns (address);
    /// @notice Signs digest with private key.
    function sign(uint256 privateKey, bytes32 digest) external returns (uint8, bytes32, bytes32);
    /// @notice Sets block timestamp.
    function warp(uint256) external;
    /// @notice Sets msg.sender for next call.
    function prank(address) external;
    /// @notice Expects revert with custom error selector.
    function expectRevert(bytes4) external;
}

/// @title Test
/// @notice Lightweight assertion helpers for repository tests.
/// @dev Keeps test suite self-contained without external test framework dependencies.
abstract contract Test {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Asserts uint256 equality.
    function assertEq(uint256 a, uint256 b, string memory err) internal pure {
        require(a == b, err);
    }

    /// @notice Asserts address equality.
    function assertEq(address a, address b, string memory err) internal pure {
        require(a == b, err);
    }

    /// @notice Asserts condition is true.
    function assertTrue(bool condition, string memory err) internal pure {
        require(condition, err);
    }

    /// @notice Asserts condition is false.
    function assertFalse(bool condition, string memory err) internal pure {
        require(!condition, err);
    }
}
