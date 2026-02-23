// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { ArbTypes } from "./ArbTypes.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { SafeTransferLib } from "./libraries/SafeTransferLib.sol";
import { Ownable } from "./utils/Ownable.sol";
import { Pausable } from "./utils/Pausable.sol";
import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";

/// @title TriangularArbExecutor
/// @notice Executes validated triangular arbitrage opportunities on Uniswap V3.
/// @dev This contract is the execution engine for the repository objective: convert a signed
///      3-hop route into on-chain swaps and return profitable proceeds to the signed recipient.
contract TriangularArbExecutor is Ownable, Pausable, ReentrancyGuard {
    using SafeTransferLib for IERC20;

    error NotSupervisor();
    error InvalidAddress();
    error InvalidRoute();
    error DeadlineExpired();
    error NoProfit();
    error InvalidAmount();
    error InvalidMinOut();

    address public supervisor;
    ISwapRouter public immutable swapRouter;

    event SupervisorUpdated(address indexed oldSupervisor, address indexed newSupervisor);
    event OpportunityExecuted(
        bytes32 indexed predictionId,
        address indexed recipient,
        address indexed payer,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOut,
        uint256 profit
    );

    modifier onlySupervisor() {
        if (msg.sender != supervisor) revert NotSupervisor();
        _;
    }

    /// @notice Initializes router and supervisor wiring for execution.
    /// @dev Router is immutable to constrain trust assumptions and reduce governance surface.
    /// @param initialOwner Owner for admin controls such as pause and supervisor rotation.
    /// @param router Uniswap V3 SwapRouter address.
    /// @param initialSupervisor Supervisor contract authorized to trigger execution.
    constructor(address initialOwner, address router, address initialSupervisor)
        Ownable(initialOwner)
    {
        if (router == address(0) || initialSupervisor == address(0)) revert InvalidAddress();
        swapRouter = ISwapRouter(router);
        supervisor = initialSupervisor;
        emit SupervisorUpdated(address(0), initialSupervisor);
    }

    /// @notice Updates supervisor authorized to call `executeOpportunity`.
    /// @dev Keeps execution authority bound to a single trusted validation layer.
    /// @param newSupervisor New supervisor address.
    function setSupervisor(address newSupervisor) external onlyOwner {
        if (newSupervisor == address(0)) revert InvalidAddress();
        address oldSupervisor = supervisor;
        supervisor = newSupervisor;
        emit SupervisorUpdated(oldSupervisor, newSupervisor);
    }

    /// @notice Pauses or unpauses opportunity execution.
    /// @param paused_ New paused state.
    function setPaused(bool paused_) external onlyOwner {
        _setPaused(paused_);
    }

    /// @notice Recovers tokens stranded in the executor.
    /// @dev Intended for emergency/accounting workflows; restricted to owner.
    /// @param token Token to recover.
    /// @param to Recipient of recovered funds.
    /// @param amount Amount to transfer.
    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        if (token == address(0) || to == address(0)) revert InvalidAddress();
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Performs the signed 3-hop swap cycle and returns profitable output.
    /// @dev Called only by `ArbSupervisor` after signature and policy checks have passed.
    /// @param opportunity Route and risk constraints signed off-chain.
    /// @param payer Address that supplies initial `tokenIn`.
    /// @return amountOut Final amount of `tokenIn` after three swaps.
    /// @return profit Net positive delta over `opportunity.amountIn`.
    function executeOpportunity(ArbTypes.Opportunity calldata opportunity, address payer)
        external
        onlySupervisor
        whenNotPaused
        nonReentrant
        returns (uint256 amountOut, uint256 profit)
    {
        if (block.timestamp > opportunity.deadline) revert DeadlineExpired();
        if (opportunity.amountIn == 0 || opportunity.minProfit == 0) revert InvalidAmount();
        if (opportunity.minOutAB == 0 || opportunity.minOutBC == 0 || opportunity.minOutCA == 0) {
            revert InvalidMinOut();
        }
        if (
            payer == address(0) || opportunity.recipient == address(0)
                || opportunity.tokenIn == address(0) || opportunity.tokenMidA == address(0)
                || opportunity.tokenMidB == address(0)
        ) revert InvalidAddress();
        if (
            opportunity.tokenIn == opportunity.tokenMidA
                || opportunity.tokenIn == opportunity.tokenMidB
                || opportunity.tokenMidA == opportunity.tokenMidB
        ) revert InvalidRoute();

        IERC20 tokenIn = IERC20(opportunity.tokenIn);
        tokenIn.safeTransferFrom(payer, address(this), opportunity.amountIn);

        tokenIn.safeApprove(address(swapRouter), 0);
        tokenIn.safeApprove(address(swapRouter), opportunity.amountIn);
        uint256 amountOutAB = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: opportunity.tokenIn,
                tokenOut: opportunity.tokenMidA,
                fee: opportunity.feeAB,
                recipient: address(this),
                deadline: opportunity.deadline,
                amountIn: opportunity.amountIn,
                amountOutMinimum: opportunity.minOutAB,
                sqrtPriceLimitX96: 0
            })
        );
        tokenIn.safeApprove(address(swapRouter), 0);

        IERC20 tokenMidA = IERC20(opportunity.tokenMidA);
        tokenMidA.safeApprove(address(swapRouter), 0);
        tokenMidA.safeApprove(address(swapRouter), amountOutAB);
        uint256 amountOutBC = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: opportunity.tokenMidA,
                tokenOut: opportunity.tokenMidB,
                fee: opportunity.feeBC,
                recipient: address(this),
                deadline: opportunity.deadline,
                amountIn: amountOutAB,
                amountOutMinimum: opportunity.minOutBC,
                sqrtPriceLimitX96: 0
            })
        );
        tokenMidA.safeApprove(address(swapRouter), 0);

        IERC20 tokenMidB = IERC20(opportunity.tokenMidB);
        tokenMidB.safeApprove(address(swapRouter), 0);
        tokenMidB.safeApprove(address(swapRouter), amountOutBC);
        amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: opportunity.tokenMidB,
                tokenOut: opportunity.tokenIn,
                fee: opportunity.feeCA,
                recipient: address(this),
                deadline: opportunity.deadline,
                amountIn: amountOutBC,
                amountOutMinimum: opportunity.minOutCA,
                sqrtPriceLimitX96: 0
            })
        );
        tokenMidB.safeApprove(address(swapRouter), 0);

        if (amountOut <= opportunity.amountIn) revert NoProfit();
        profit = amountOut - opportunity.amountIn;
        if (profit < opportunity.minProfit) revert NoProfit();

        tokenIn.safeTransfer(opportunity.recipient, amountOut);

        emit OpportunityExecuted(
            opportunity.predictionId,
            opportunity.recipient,
            payer,
            opportunity.tokenIn,
            opportunity.amountIn,
            amountOut,
            profit
        );
    }
}
