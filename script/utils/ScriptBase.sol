// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

/// @title Vm
/// @notice Minimal Foundry cheatcode interface used by project scripts.
/// @dev This interface decouples script contracts from forge-std while preserving typed env access.
interface Vm {
    /// @notice Reads uint256 environment value by key.
    function envUint(string calldata key) external returns (uint256);
    /// @notice Reads address environment value by key.
    function envAddress(string calldata key) external returns (address);
    /// @notice Reads bytes32 environment value by key.
    function envBytes32(string calldata key) external returns (bytes32);
    /// @notice Reads bytes environment value by key.
    function envBytes(string calldata key) external returns (bytes memory);
    /// @notice Starts transaction broadcast context with private key.
    function startBroadcast(uint256 privateKey) external;
    /// @notice Stops transaction broadcast context.
    function stopBroadcast() external;
}

/// @title ScriptBase
/// @notice Shared base contract for deployment and execution scripts.
/// @dev Provides a single `vm` cheatcode handle to keep script modules consistent.
abstract contract ScriptBase {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
}
