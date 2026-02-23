// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import {ArbTypes} from "./ArbTypes.sol";
import {ECDSA} from "./libraries/ECDSA.sol";
import {EIP712Domain} from "./libraries/EIP712Domain.sol";
import {Ownable} from "./utils/Ownable.sol";
import {Pausable} from "./utils/Pausable.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";
import {TriangularArbExecutor} from "./TriangularArbExecutor.sol";

contract ArbSupervisor is Ownable, Pausable, ReentrancyGuard, EIP712Domain {
    error InvalidAddress();
    error UnauthorizedCaller();
    error InvalidFeeTier();
    error MaxAmountExceeded();
    error SignatureExpired();
    error ReplayDetected();
    error InvalidSignature();

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

    function setPaused(bool paused_) external onlyOwner {
        _setPaused(paused_);
    }

    function setExecutor(address newExecutor) external onlyOwner {
        if (newExecutor == address(0)) revert InvalidAddress();
        address oldExecutor = address(executor);
        executor = TriangularArbExecutor(newExecutor);
        emit ExecutorUpdated(oldExecutor, newExecutor);
    }

    function setSigner(address signer, bool allowed) external onlyOwner {
        if (signer == address(0)) revert InvalidAddress();
        isSigner[signer] = allowed;
        emit SignerUpdated(signer, allowed);
    }

    function setAllowedFeeTier(uint24 fee, bool allowed) external onlyOwner {
        allowedFeeTier[fee] = allowed;
        emit AllowedFeeTierUpdated(fee, allowed);
    }

    function setMaxAmountIn(uint256 newMaxAmountIn) external onlyOwner {
        maxAmountIn = newMaxAmountIn;
        emit MaxAmountInUpdated(newMaxAmountIn);
    }

    function setRecipientCallerMatch(bool enforce) external onlyOwner {
        enforceRecipientCallerMatch = enforce;
        emit RecipientCallerMatchUpdated(enforce);
    }

    function executePrediction(ArbTypes.Opportunity calldata opportunity, bytes calldata signature)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 amountOut, uint256 profit)
    {
        if (block.timestamp > opportunity.deadline) revert SignatureExpired();
        if (maxAmountIn != 0 && opportunity.amountIn > maxAmountIn) revert MaxAmountExceeded();
        if (!allowedFeeTier[opportunity.feeAB] || !allowedFeeTier[opportunity.feeBC] || !allowedFeeTier[opportunity.feeCA]) {
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
