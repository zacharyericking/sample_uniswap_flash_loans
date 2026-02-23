// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

interface Vm {
    function envUint(string calldata key) external returns (uint256);
    function envAddress(string calldata key) external returns (address);
    function envBytes32(string calldata key) external returns (bytes32);
    function envBytes(string calldata key) external returns (bytes memory);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

abstract contract ScriptBase {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
}
