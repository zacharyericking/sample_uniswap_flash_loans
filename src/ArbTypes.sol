// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title ArbTypes
/// @notice Shared typed-data definitions for supervisor-authorized opportunities.
/// @dev This file anchors the canonical `Opportunity` payload used across off-chain signing,
///      on-chain signature verification in `ArbSupervisor`, and execution in `TriangularArbExecutor`.
library ArbTypes {
    /// @notice Signed opportunity payload for a triangular swap cycle.
    /// @dev Every field participates in the EIP-712 hash to bind execution constraints.
    struct Opportunity {
        /// @notice Optional external identifier for strategy/reconciliation systems.
        bytes32 predictionId;
        /// @notice Recipient of the final token output after the 3-hop execution.
        address recipient;
        /// @notice Token sold in hop 1 and bought back in hop 3.
        address tokenIn;
        /// @notice Intermediate token used in hop 1 -> hop 2.
        address tokenMidA;
        /// @notice Intermediate token used in hop 2 -> hop 3.
        address tokenMidB;
        /// @notice Uniswap V3 fee tier for hop tokenIn -> tokenMidA.
        uint24 feeAB;
        /// @notice Uniswap V3 fee tier for hop tokenMidA -> tokenMidB.
        uint24 feeBC;
        /// @notice Uniswap V3 fee tier for hop tokenMidB -> tokenIn.
        uint24 feeCA;
        /// @notice Input amount transferred from payer before swaps start.
        uint256 amountIn;
        /// @notice Slippage floor for hop tokenIn -> tokenMidA.
        uint256 minOutAB;
        /// @notice Slippage floor for hop tokenMidA -> tokenMidB.
        uint256 minOutBC;
        /// @notice Slippage floor for hop tokenMidB -> tokenIn.
        uint256 minOutCA;
        /// @notice Minimum required net profit denominated in `tokenIn`.
        uint256 minProfit;
        /// @notice Strategy nonce used by signers/off-chain systems for uniqueness.
        uint256 nonce;
        /// @notice Absolute Unix timestamp after which execution must revert.
        uint256 deadline;
    }

    bytes32 internal constant OPPORTUNITY_TYPEHASH = keccak256(
        "Opportunity(bytes32 predictionId,address recipient,address tokenIn,address tokenMidA,address tokenMidB,uint24 feeAB,uint24 feeBC,uint24 feeCA,uint256 amountIn,uint256 minOutAB,uint256 minOutBC,uint256 minOutCA,uint256 minProfit,uint256 nonce,uint256 deadline)"
    );

    /// @notice Hashes an opportunity according to the contract's typed-data schema.
    /// @dev This function is consumed by `ArbSupervisor` to build EIP-712 digests for signature recovery.
    /// @param opportunity Opportunity payload provided by the caller and previously signed off-chain.
    /// @return Struct hash compatible with EIP-712 typed data encoding.
    function hashOpportunity(Opportunity calldata opportunity) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                OPPORTUNITY_TYPEHASH,
                opportunity.predictionId,
                opportunity.recipient,
                opportunity.tokenIn,
                opportunity.tokenMidA,
                opportunity.tokenMidB,
                opportunity.feeAB,
                opportunity.feeBC,
                opportunity.feeCA,
                opportunity.amountIn,
                opportunity.minOutAB,
                opportunity.minOutBC,
                opportunity.minOutCA,
                opportunity.minProfit,
                opportunity.nonce,
                opportunity.deadline
            )
        );
    }
}
