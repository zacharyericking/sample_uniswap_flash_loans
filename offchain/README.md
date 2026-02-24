Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `offchain/` Module

Objective: produce validated EIP-712 signatures for opportunities consumed by `ArbSupervisor`.

- `signOpportunity.ts`: reads env configuration, validates types/ranges, and signs `ArbTypes.Opportunity`.

This module provides the trusted signing input to the on-chain authorization flow.
