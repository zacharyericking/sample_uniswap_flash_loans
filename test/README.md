Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `test/` Module

Objective: verify security and behavior of supervisor/executor modules.

- `ArbSupervisor.t.sol`: signature validation, replay, fee policy, deadline, and reentrancy checks.
- `TriangularArbExecutor.t.sol`: supervisor-only execution, pause behavior, and owner rescue controls.
- `mocks/`: deterministic and adversarial components used by tests.
- `utils/`: minimal local test harness helpers.

The test suite validates the repository's core objective: safe, profitable, authorized execution.
