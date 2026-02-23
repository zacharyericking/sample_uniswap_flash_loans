// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

library ArbTypes {
    struct Opportunity {
        bytes32 predictionId;
        address recipient;
        address tokenIn;
        address tokenMidA;
        address tokenMidB;
        uint24 feeAB;
        uint24 feeBC;
        uint24 feeCA;
        uint256 amountIn;
        uint256 minOutAB;
        uint256 minOutBC;
        uint256 minOutCA;
        uint256 minProfit;
        uint256 nonce;
        uint256 deadline;
    }

    bytes32 internal constant OPPORTUNITY_TYPEHASH = keccak256(
        "Opportunity(bytes32 predictionId,address recipient,address tokenIn,address tokenMidA,address tokenMidB,uint24 feeAB,uint24 feeBC,uint24 feeCA,uint256 amountIn,uint256 minOutAB,uint256 minOutBC,uint256 minOutCA,uint256 minProfit,uint256 nonce,uint256 deadline)"
    );

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
