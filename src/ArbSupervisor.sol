// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { ArbTypes } from "./ArbTypes.sol";
import { ECDSA } from "./libraries/ECDSA.sol";
import { EIP712Domain } from "./libraries/EIP712Domain.sol";
import { Ownable } from "./utils/Ownable.sol";
import { Pausable } from "./utils/Pausable.sol";
import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { TriangularArbExecutor } from "./TriangularArbExecutor.sol";

/// @title ArbSupervisor
/// @notice Validates signed arbitrage opportunities before delegating execution.
/// @dev This contract is the trust gateway of the repository: it enforces signer policy,
///      replay protection, fee policy, and caller/recipient constraints before allowing
///      `TriangularArbExecutor` to move user funds.
contract ArbSupervisor is Ownable, Pausable, ReentrancyGuard, EIP712Domain {
    error InvalidAddress();
    error UnauthorizedCaller();
    error InvalidFeeTier();
    error MaxAmountExceeded();
    error SignatureExpired();
    error ReplayDetected();
    error InvalidSignature();
    error InvalidAmount();
    error InvalidRoute();
    error InvalidMinOut();

    TriangularArbExecutor public executor;
    uint256 public maxAmountIn;
    bool public enforceRecipientCallerMatch;

    mapping(address => bool) public isSigner;
    mapping(bytes32 => bool) public usedPrediction;
    mapping(uint24 => bool) public allowedFeeTier;

    event SignerUpdated(address indexed signer, bool allowed);
    event AllowedFeeTierUpdated(uint24 indexed fee, bool allowed);
    event MaxAmountInUpdated(uint256 maxAmountIn);
    event RecipientCallerMatchUpdated(bool enforce);
    event ExecutorUpdated(address indexed oldExecutor, address indexed newExecutor);
    event PredictionExecuted(
        bytes32 indexed predictionId,
        address indexed signer,
        address indexed caller,
        uint256 amountOut,
        uint256 profit
    );

    /// @notice Initializes supervisor ownership, executor, and default fee policy.
    /// @dev Sets EIP-712 domain to `ArbSupervisor` version `1` for off-chain signing parity.
    /// @param initialOwner Owner for administrative controls.
    /// @param executorAddress Executor contract that performs validated opportunities.
    /// @param initialMaxAmountIn Optional max input cap; zero disables cap.
    constructor(address initialOwner, address executorAddress, uint256 initialMaxAmountIn)
        Ownable(initialOwner)
        EIP712Domain("ArbSupervisor", "1")
    {
        if (executorAddress == address(0)) revert InvalidAddress();
        executor = TriangularArbExecutor(executorAddress);
        maxAmountIn = initialMaxAmountIn;
        enforceRecipientCallerMatch = true;

        allowedFeeTier[500] = true;
        allowedFeeTier[3000] = true;
        allowedFeeTier[10_000] = true;
    }

    /// @notice Pauses or unpauses prediction execution.
    /// @dev Supports incident response without redeploying supervisor or executor.
    /// @param paused_ New paused state.
    function setPaused(bool paused_) external onlyOwner {
        _setPaused(paused_);
    }

    /// @notice Updates executor contract used for post-validation execution.
    /// @dev This admin action changes the downstream trust target and must be tightly controlled.
    /// @param newExecutor New executor address.
    function setExecutor(address newExecutor) external onlyOwner {
        if (newExecutor == address(0)) revert InvalidAddress();
        address oldExecutor = address(executor);
        executor = TriangularArbExecutor(newExecutor);
        emit ExecutorUpdated(oldExecutor, newExecutor);
    }

    /// @notice Grants or revokes authorization for an off-chain signer.
    /// @dev Signers are the root of opportunity admission, so rotation events are emitted.
    /// @param signer Signer address to update.
    /// @param allowed Whether signatures from signer should be accepted.
    function setSigner(address signer, bool allowed) external onlyOwner {
        if (signer == address(0)) revert InvalidAddress();
        isSigner[signer] = allowed;
        emit SignerUpdated(signer, allowed);
    }

    /// @notice Adds or removes a fee tier from the execution allowlist.
    /// @dev Restricting fee tiers reduces unsupported-path risk and invalid routing assumptions.
    /// @param fee Uniswap V3 fee tier.
    /// @param allowed Whether fee tier should be accepted.
    function setAllowedFeeTier(uint24 fee, bool allowed) external onlyOwner {
        if (fee == 0) revert InvalidFeeTier();
        allowedFeeTier[fee] = allowed;
        emit AllowedFeeTierUpdated(fee, allowed);
    }

    /// @notice Sets maximum input amount accepted per signed opportunity.
    /// @dev A value of zero disables the cap; otherwise execution reverts above this limit.
    /// @param newMaxAmountIn New cap value.
    function setMaxAmountIn(uint256 newMaxAmountIn) external onlyOwner {
        maxAmountIn = newMaxAmountIn;
        emit MaxAmountInUpdated(newMaxAmountIn);
    }

    /// @notice Configures whether caller must equal signed recipient.
    /// @dev Enabling this is a strict anti-front-running posture for user-submitted executions.
    /// @param enforce Whether to require `msg.sender == opportunity.recipient`.
    function setRecipientCallerMatch(bool enforce) external onlyOwner {
        enforceRecipientCallerMatch = enforce;
        emit RecipientCallerMatchUpdated(enforce);
    }

    /// @notice Verifies and executes a signed arbitrage opportunity.
    /// @dev This function secures module objective by enforcing signature validity, replay safety,
    ///      route constraints, and policy checks before forwarding to executor.
    /// @param opportunity Signed route/amount/slippage/profit constraints.
    /// @param signature EIP-712 signature over `opportunity` by an authorized signer.
    /// @return amountOut Final token output returned by the executor.
    /// @return profit Net profit in `tokenIn` units.
    function executePrediction(ArbTypes.Opportunity calldata opportunity, bytes calldata signature)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amountOut, uint256 profit)
    {
        if (opportunity.amountIn == 0) revert InvalidAmount();
        if (
            opportunity.recipient == address(0) || opportunity.tokenIn == address(0)
                || opportunity.tokenMidA == address(0) || opportunity.tokenMidB == address(0)
        ) revert InvalidAddress();
        if (
            opportunity.tokenIn == opportunity.tokenMidA
                || opportunity.tokenIn == opportunity.tokenMidB
                || opportunity.tokenMidA == opportunity.tokenMidB
        ) revert InvalidRoute();
        if (opportunity.minOutAB == 0 || opportunity.minOutBC == 0 || opportunity.minOutCA == 0) {
            revert InvalidMinOut();
        }
        if (block.timestamp > opportunity.deadline) revert SignatureExpired();
        if (maxAmountIn != 0 && opportunity.amountIn > maxAmountIn) revert MaxAmountExceeded();
        if (
            !allowedFeeTier[opportunity.feeAB] || !allowedFeeTier[opportunity.feeBC]
                || !allowedFeeTier[opportunity.feeCA]
        ) {
            revert InvalidFeeTier();
        }
        if (enforceRecipientCallerMatch && opportunity.recipient != msg.sender) {
            revert UnauthorizedCaller();
        }

        bytes32 digest = _hashTypedDataV4(ArbTypes.hashOpportunity(opportunity));
        if (usedPrediction[digest]) revert ReplayDetected();

        address signer = ECDSA.recover(digest, signature);
        if (!isSigner[signer]) revert InvalidSignature();

        usedPrediction[digest] = true;
        if (opportunity.predictionId != bytes32(0)) {
            if (usedPrediction[opportunity.predictionId]) revert ReplayDetected();
            usedPrediction[opportunity.predictionId] = true;
        }

        (amountOut, profit) = executor.executeOpportunity(opportunity, msg.sender);
        emit PredictionExecuted(opportunity.predictionId, signer, msg.sender, amountOut, profit);
    }
}
