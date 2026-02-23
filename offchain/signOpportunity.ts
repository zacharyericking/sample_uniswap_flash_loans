// Author: Zachary King - github.com/zacharyericking
import { Wallet, TypedDataDomain } from "ethers";

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

async function main() {
  const signerPk = requiredEnv("SUPERVISOR_SIGNER_PRIVATE_KEY");

  const domain: TypedDataDomain = {
    name: "ArbSupervisor",
    version: "1",
    chainId: Number(requiredEnv("CHAIN_ID")),
    verifyingContract: requiredEnv("SUPERVISOR_ADDRESS"),
  };

  const opportunity: Opportunity = {
    predictionId: requiredEnv("PREDICTION_ID"),
    recipient: requiredEnv("RECIPIENT"),
    tokenIn: requiredEnv("TOKEN_IN"),
    tokenMidA: requiredEnv("TOKEN_MID_A"),
    tokenMidB: requiredEnv("TOKEN_MID_B"),
    feeAB: Number(requiredEnv("FEE_AB")),
    feeBC: Number(requiredEnv("FEE_BC")),
    feeCA: Number(requiredEnv("FEE_CA")),
    amountIn: requiredEnv("AMOUNT_IN"),
    minOutAB: requiredEnv("MIN_OUT_AB"),
    minOutBC: requiredEnv("MIN_OUT_BC"),
    minOutCA: requiredEnv("MIN_OUT_CA"),
    minProfit: requiredEnv("MIN_PROFIT"),
    nonce: requiredEnv("NONCE"),
    deadline: requiredEnv("DEADLINE"),
  };

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
