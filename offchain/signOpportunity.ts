// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// Author: Zachary King - github.com/zacharyericking
/**
 * Objective:
 * Generate a deterministic EIP-712 signature for `ArbTypes.Opportunity` so
 * `ArbSupervisor` can authorize and execute a constrained triangular opportunity.
 */
import { Wallet, TypedDataDomain, getAddress, isHexString } from "ethers";

type Opportunity = {
  predictionId: string;
  recipient: string;
  tokenIn: string;
  tokenMidA: string;
  tokenMidB: string;
  feeAB: number;
  feeBC: number;
  feeCA: number;
  amountIn: string;
  minOutAB: string;
  minOutBC: string;
  minOutCA: string;
  minProfit: string;
  nonce: string;
  deadline: string;
};

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.length === 0) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

function requiredAddress(name: string): string {
  return getAddress(requiredEnv(name));
}

function requiredUintString(name: string): string {
  const raw = requiredEnv(name);
  const parsed = BigInt(raw);
  if (parsed < 0n) {
    throw new Error(`Expected non-negative integer env var: ${name}`);
  }
  return parsed.toString();
}

function requiredUint24(name: string): number {
  const raw = BigInt(requiredEnv(name));
  if (raw <= 0n || raw > 0xffffffn) {
    throw new Error(`Expected uint24 > 0 env var: ${name}`);
  }
  return Number(raw);
}

function requiredBytes32(name: string): string {
  const value = requiredEnv(name);
  if (!isHexString(value, 32)) {
    throw new Error(`Expected bytes32 env var: ${name}`);
  }
  return value;
}

async function main() {
  const signerPk = requiredEnv("SUPERVISOR_SIGNER_PRIVATE_KEY");
  if (!isHexString(signerPk) || signerPk.length !== 66) {
    throw new Error("SUPERVISOR_SIGNER_PRIVATE_KEY must be a 32-byte hex key");
  }

  const domain: TypedDataDomain = {
    name: "ArbSupervisor",
    version: "1",
    chainId: Number(requiredUintString("CHAIN_ID")),
    verifyingContract: requiredAddress("SUPERVISOR_ADDRESS"),
  };
  if (!Number.isSafeInteger(domain.chainId) || domain.chainId <= 0) {
    throw new Error("CHAIN_ID must be a positive safe integer");
  }

  const opportunity: Opportunity = {
    predictionId: requiredBytes32("PREDICTION_ID"),
    recipient: requiredAddress("RECIPIENT"),
    tokenIn: requiredAddress("TOKEN_IN"),
    tokenMidA: requiredAddress("TOKEN_MID_A"),
    tokenMidB: requiredAddress("TOKEN_MID_B"),
    feeAB: requiredUint24("FEE_AB"),
    feeBC: requiredUint24("FEE_BC"),
    feeCA: requiredUint24("FEE_CA"),
    amountIn: requiredUintString("AMOUNT_IN"),
    minOutAB: requiredUintString("MIN_OUT_AB"),
    minOutBC: requiredUintString("MIN_OUT_BC"),
    minOutCA: requiredUintString("MIN_OUT_CA"),
    minProfit: requiredUintString("MIN_PROFIT"),
    nonce: requiredUintString("NONCE"),
    deadline: requiredUintString("DEADLINE"),
  };
  if (
    opportunity.tokenIn === opportunity.tokenMidA ||
    opportunity.tokenIn === opportunity.tokenMidB ||
    opportunity.tokenMidA === opportunity.tokenMidB
  ) {
    throw new Error("Route tokens must be distinct");
  }
  if (
    BigInt(opportunity.amountIn) === 0n ||
    BigInt(opportunity.minOutAB) === 0n ||
    BigInt(opportunity.minOutBC) === 0n ||
    BigInt(opportunity.minOutCA) === 0n ||
    BigInt(opportunity.minProfit) === 0n
  ) {
    throw new Error("amountIn, minOutAB, minOutBC, minOutCA, minProfit must all be > 0");
  }
  if (BigInt(opportunity.deadline) === 0n) {
    throw new Error("deadline must be > 0");
  }

  const types = {
    Opportunity: [
      { name: "predictionId", type: "bytes32" },
      { name: "recipient", type: "address" },
      { name: "tokenIn", type: "address" },
      { name: "tokenMidA", type: "address" },
      { name: "tokenMidB", type: "address" },
      { name: "feeAB", type: "uint24" },
      { name: "feeBC", type: "uint24" },
      { name: "feeCA", type: "uint24" },
      { name: "amountIn", type: "uint256" },
      { name: "minOutAB", type: "uint256" },
      { name: "minOutBC", type: "uint256" },
      { name: "minOutCA", type: "uint256" },
      { name: "minProfit", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  };

  const wallet = new Wallet(signerPk);
  const signature = await wallet.signTypedData(domain, types, opportunity);

  console.log("SIGNER:", wallet.address);
  console.log("OPPORTUNITY_SIGNATURE:", signature);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
