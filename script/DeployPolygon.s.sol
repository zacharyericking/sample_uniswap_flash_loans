// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

import {ArbSupervisor} from "../src/ArbSupervisor.sol";
import {TriangularArbExecutor} from "../src/TriangularArbExecutor.sol";
import {ScriptBase} from "./utils/ScriptBase.sol";

contract DeployPolygon is ScriptBase {
    // Uniswap V3 SwapRouter address used on Polygon.
    address internal constant POLYGON_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    function run() external returns (TriangularArbExecutor executor, ArbSupervisor supervisor) {
        uint256 deployerPk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address signer = vm.envAddress("SUPERVISOR_SIGNER");
        uint256 maxAmountIn = vm.envUint("MAX_AMOUNT_IN");

        vm.startBroadcast(deployerPk);

        executor = new TriangularArbExecutor(owner, POLYGON_SWAP_ROUTER, owner);
        supervisor = new ArbSupervisor(owner, address(executor), maxAmountIn);
        executor.setSupervisor(address(supervisor));
        supervisor.setSigner(signer, true);

        vm.stopBroadcast();
    }
}
