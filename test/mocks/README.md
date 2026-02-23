Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `test/mocks/` Module

Objective: provide controlled dependencies and adversarial behavior for security testing.

- `MockERC20.sol`: deterministic token for balance/allowance tests.
- `MockSwapRouter.sol`: deterministic swap output engine with min-out checks.
- `ReentrantToken.sol`: malicious token attempting callback reentrancy.

Mocks allow precise validation of error paths and invariants in production contracts.
