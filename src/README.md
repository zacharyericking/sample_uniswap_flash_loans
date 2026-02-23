Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `src/` Module

Objective: production smart contracts for signature-gated triangular arbitrage.

- `ArbSupervisor.sol`: validates signed opportunities, replay policy, and fee/amount constraints.
- `TriangularArbExecutor.sol`: executes 3-hop swaps and enforces profitability.
- `ArbTypes.sol`: canonical signed payload schema shared by off-chain/on-chain flows.
- `interfaces/`: external dependencies (ERC20 and Uniswap router interfaces).
- `libraries/`: cryptography and safe token transfer helpers.
- `utils/`: reusable security primitives (ownership, pause, reentrancy).
