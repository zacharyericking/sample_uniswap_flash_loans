# `src/interfaces/` Module

Objective: stable protocol interfaces used by core contracts.

- `IERC20.sol`: minimal ERC20 surface used for transfers, approvals, and balance checks.
- `ISwapRouter.sol`: minimal Uniswap V3 exact-input single-hop swap interface.

These interfaces keep production modules decoupled from vendor packages while preserving strict typing.
