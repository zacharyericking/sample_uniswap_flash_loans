// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

import { ArbSupervisor } from "../src/ArbSupervisor.sol";
import { TriangularArbExecutor } from "../src/TriangularArbExecutor.sol";
import { ScriptBase } from "./utils/ScriptBase.sol";

/// @title DeployPolygon
/// @notice Deploys executor + supervisor pair configured for Polygon.
/// @dev This script supports repository objective by provisioning secure production wiring:
///      router, owner controls, supervisor linkage, and authorized signer registration.
contract DeployPolygon is ScriptBase {
    error InvalidConfig();

    // Uniswap V3 SwapRouter address used on Polygon.
    address internal constant POLYGON_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @notice Deploys and wires core contracts on Polygon.
    /// @dev Requires env vars for deployer, owner, signer, and max amount policy.
    /// @return executor Deployed execution engine contract.
    /// @return supervisor Deployed validation/supervision contract.
    function run() external returns (TriangularArbExecutor executor, ArbSupervisor supervisor) {
        uint256 deployerPk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address signer = vm.envAddress("SUPERVISOR_SIGNER");
        uint256 maxAmountIn = vm.envUint("MAX_AMOUNT_IN");
        if (deployerPk == 0 || owner == address(0) || signer == address(0)) revert InvalidConfig();

        vm.startBroadcast(deployerPk);

        executor = new TriangularArbExecutor(owner, POLYGON_SWAP_ROUTER, owner);
        supervisor = new ArbSupervisor(owner, address(executor), maxAmountIn);
        executor.setSupervisor(address(supervisor));
        supervisor.setSigner(signer, true);

        vm.stopBroadcast();
    }
}
