# uniswap_flash_loans
Author: Zachary King - github.com/zacharyericking

Smart Contracts to Execute Flash Loans for Arbitrage on Polygon and Arbitrum.

## Deployment Scripts

### Polygon

Set required environment variables:

- `DEPLOYER_PRIVATE_KEY`
- `OWNER`
- `SUPERVISOR_SIGNER`
- `MAX_AMOUNT_IN`
- `POLYGON_RPC_URL`

Run:

`forge script script/DeployPolygon.s.sol:DeployPolygon --rpc-url $POLYGON_RPC_URL --broadcast`

### Arbitrum

Set required environment variables:

- `DEPLOYER_PRIVATE_KEY`
- `OWNER`
- `SUPERVISOR_SIGNER`
- `MAX_AMOUNT_IN`
- `ARBITRUM_RPC_URL`

Run:

`forge script script/DeployArbitrum.s.sol:DeployArbitrum --rpc-url $ARBITRUM_RPC_URL --broadcast`

## Supervisor-Operated Execution Flow

1. Predictor produces a candidate triangular opportunity.
2. Authorized signer creates an EIP-712 signature for `ArbTypes.Opportunity`.
3. User/caller submits opportunity + signature to `ArbSupervisor.executePrediction`.
4. `ArbSupervisor` verifies signature, replay, deadline, and fee policy.
5. `TriangularArbExecutor` performs 3-hop swap and enforces positive profit.

### Off-Chain Signature Generation (EIP-712)

Use:

- `offchain/signOpportunity.ts`

Required environment variables:

- `SUPERVISOR_SIGNER_PRIVATE_KEY`
- `CHAIN_ID`
- `SUPERVISOR_ADDRESS`
- `PREDICTION_ID`
- `RECIPIENT`
- `TOKEN_IN`
- `TOKEN_MID_A`
- `TOKEN_MID_B`
- `FEE_AB`
- `FEE_BC`
- `FEE_CA`
- `AMOUNT_IN`
- `MIN_OUT_AB`
- `MIN_OUT_BC`
- `MIN_OUT_CA`
- `MIN_PROFIT`
- `NONCE`
- `DEADLINE`

Example run:

`npx tsx offchain/signOpportunity.ts`

The script prints `OPPORTUNITY_SIGNATURE` for on-chain execution.

### Execute Through Supervisor

Use:

- `script/ExecutePrediction.s.sol`

Set environment variables:

- `CALLER_PRIVATE_KEY`
- `SUPERVISOR`
- `OPPORTUNITY_SIGNATURE`
- `PREDICTION_ID`
- `RECIPIENT`
- `TOKEN_IN`
- `TOKEN_MID_A`
- `TOKEN_MID_B`
- `FEE_AB`
- `FEE_BC`
- `FEE_CA`
- `AMOUNT_IN`
- `MIN_OUT_AB`
- `MIN_OUT_BC`
- `MIN_OUT_CA`
- `MIN_PROFIT`
- `NONCE`
- `DEADLINE`
- `RPC_URL`

Run:

`forge script script/ExecutePrediction.s.sol:ExecutePrediction --rpc-url $RPC_URL --broadcast`
