Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `src/utils/` Module

Objective: security base contracts reused by production modules.

- `Ownable.sol`: privileged-admin access control.
- `Pausable.sol`: emergency stop behavior.
- `ReentrancyGuard.sol`: nested-call protection.

These utilities enforce consistent security posture across supervisor and executor contracts.
