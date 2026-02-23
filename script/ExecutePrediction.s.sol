// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
// Author: Zachary King - github.com/zacharyericking
pragma solidity ^0.8.26;

import { ArbSupervisor } from "../src/ArbSupervisor.sol";
import { ArbTypes } from "../src/ArbTypes.sol";
import { ScriptBase } from "./utils/ScriptBase.sol";

/// @title ExecutePrediction
/// @notice Broadcasts a signed `Opportunity` to `ArbSupervisor` for execution.
/// @dev This script connects off-chain signature output to on-chain execution using strict
///      env validation so malformed configuration fails before broadcasting transactions.
contract ExecutePrediction is ScriptBase {
    error InvalidConfig();
    error InvalidFee();
    error InvalidSignature();

    /// @notice Executes an already signed opportunity through supervisor.
    /// @return amountOut Final output in `tokenIn` units returned by supervisor/executor.
    /// @return profit Net profit returned by supervisor/executor.
    function run() external returns (uint256 amountOut, uint256 profit) {
        uint256 callerPk = vm.envUint("CALLER_PRIVATE_KEY");
        ArbSupervisor supervisor = ArbSupervisor(vm.envAddress("SUPERVISOR"));
        bytes memory signature = vm.envBytes("OPPORTUNITY_SIGNATURE");
        if (callerPk == 0 || address(supervisor) == address(0)) revert InvalidConfig();
        if (signature.length != 65) revert InvalidSignature();

        ArbTypes.Opportunity memory opportunity = ArbTypes.Opportunity({
            predictionId: vm.envBytes32("PREDICTION_ID"),
            recipient: vm.envAddress("RECIPIENT"),
            tokenIn: vm.envAddress("TOKEN_IN"),
            tokenMidA: vm.envAddress("TOKEN_MID_A"),
            tokenMidB: vm.envAddress("TOKEN_MID_B"),
            feeAB: _readFee("FEE_AB"),
            feeBC: _readFee("FEE_BC"),
            feeCA: _readFee("FEE_CA"),
            amountIn: vm.envUint("AMOUNT_IN"),
            minOutAB: vm.envUint("MIN_OUT_AB"),
            minOutBC: vm.envUint("MIN_OUT_BC"),
            minOutCA: vm.envUint("MIN_OUT_CA"),
            minProfit: vm.envUint("MIN_PROFIT"),
            nonce: vm.envUint("NONCE"),
            deadline: vm.envUint("DEADLINE")
        });
        if (
            opportunity.recipient == address(0) || opportunity.tokenIn == address(0)
                || opportunity.tokenMidA == address(0) || opportunity.tokenMidB == address(0)
        ) revert InvalidConfig();

        vm.startBroadcast(callerPk);
        (amountOut, profit) = supervisor.executePrediction(opportunity, signature);
        vm.stopBroadcast();
    }

    /// @notice Reads and validates uint24-compatible fee from env.
    /// @param key Environment variable key.
    /// @return fee Validated fee tier value.
    function _readFee(string memory key) internal returns (uint24 fee) {
        uint256 rawFee = vm.envUint(key);
        if (rawFee > type(uint24).max || rawFee == 0) revert InvalidFee();
        fee = uint24(rawFee);
    }
}
