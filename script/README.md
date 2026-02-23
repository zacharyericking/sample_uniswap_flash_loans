Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

# `script/` Module

Objective: operational automation for deployment and signed opportunity execution.

- `DeployPolygon.s.sol`: deploys contracts and configures signer on Polygon.
- `DeployArbitrum.s.sol`: deploys contracts and configures signer on Arbitrum.
- `ExecutePrediction.s.sol`: submits a signed opportunity to supervisor.
- `utils/ScriptBase.sol`: shared Foundry cheatcode adapter.

Scripts enforce typed environment validation before broadcasting transactions.
