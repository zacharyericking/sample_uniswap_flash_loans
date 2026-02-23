// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

import {ArbSupervisor} from "../src/ArbSupervisor.sol";
import {ArbTypes} from "../src/ArbTypes.sol";
import {ScriptBase} from "./utils/ScriptBase.sol";

contract ExecutePrediction is ScriptBase {
    function run() external returns (uint256 amountOut, uint256 profit) {
        uint256 callerPk = vm.envUint("CALLER_PRIVATE_KEY");
        ArbSupervisor supervisor = ArbSupervisor(vm.envAddress("SUPERVISOR"));
        bytes memory signature = vm.envBytes("OPPORTUNITY_SIGNATURE");

        ArbTypes.Opportunity memory opportunity = ArbTypes.Opportunity({
            predictionId: vm.envBytes32("PREDICTION_ID"),
            recipient: vm.envAddress("RECIPIENT"),
            tokenIn: vm.envAddress("TOKEN_IN"),
            tokenMidA: vm.envAddress("TOKEN_MID_A"),
            tokenMidB: vm.envAddress("TOKEN_MID_B"),
            feeAB: uint24(vm.envUint("FEE_AB")),
            feeBC: uint24(vm.envUint("FEE_BC")),
            feeCA: uint24(vm.envUint("FEE_CA")),
            amountIn: vm.envUint("AMOUNT_IN"),
            minOutAB: vm.envUint("MIN_OUT_AB"),
            minOutBC: vm.envUint("MIN_OUT_BC"),
            minOutCA: vm.envUint("MIN_OUT_CA"),
            minProfit: vm.envUint("MIN_PROFIT"),
            nonce: vm.envUint("NONCE"),
            deadline: vm.envUint("DEADLINE")
        });

        vm.startBroadcast(callerPk);
        (amountOut, profit) = supervisor.executePrediction(opportunity, signature);
        vm.stopBroadcast();
    }
}
