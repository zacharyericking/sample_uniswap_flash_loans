// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { Test } from "./utils/Test.sol";
import { ArbTypes } from "../src/ArbTypes.sol";
import { ArbSupervisor } from "../src/ArbSupervisor.sol";
import { TriangularArbExecutor } from "../src/TriangularArbExecutor.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockSwapRouter } from "./mocks/MockSwapRouter.sol";
import { ReentrantToken } from "./mocks/ReentrantToken.sol";

/// @title ArbSupervisorTest
/// @notice Verifies signature-gated arbitrage supervision and security invariants.
/// @dev These tests map to repository objective by proving execution is authorized,
///      replay-safe, profitable, and reentrancy-resistant.
contract ArbSupervisorTest is Test {
    uint256 private constant SIGNER_PK = 0xA11CE;
    uint256 private constant OPERATOR_PK = 0xB0B;
    uint256 private constant START_BALANCE = 1_000_000e18;

    MockERC20 internal tokenIn;
    MockERC20 internal tokenMidA;
    MockERC20 internal tokenMidB;
    MockSwapRouter internal router;
    TriangularArbExecutor internal executor;
    ArbSupervisor internal supervisor;

    address internal owner;
    address internal signer;
    address internal operator;

    /// @notice Deploys contracts and baseline route configuration for each test.
    function setUp() public {
        owner = address(this);
        signer = vm.addr(SIGNER_PK);
        operator = vm.addr(OPERATOR_PK);

        tokenIn = new MockERC20("TokenIn", "TIN", 18);
        tokenMidA = new MockERC20("TokenMidA", "TMA", 18);
        tokenMidB = new MockERC20("TokenMidB", "TMB", 18);
        router = new MockSwapRouter();

        executor = new TriangularArbExecutor(owner, address(router), owner);
        supervisor = new ArbSupervisor(owner, address(executor), 500_000e18);
        executor.setSupervisor(address(supervisor));
        supervisor.setSigner(signer, true);

        tokenIn.mint(operator, START_BALANCE);
        vm.prank(operator);
        tokenIn.approve(address(executor), type(uint256).max);

        router.setRate(address(tokenIn), address(tokenMidA), 500, 1, 1);
        router.setRate(address(tokenMidA), address(tokenMidB), 3000, 1, 1);
    }

    /// @notice Confirms profitable opportunity execution returns expected output/profit.
    function testExecutePredictionProfitable() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);

        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 10e18
        );
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        uint256 start = tokenIn.balanceOf(operator);
        vm.prank(operator);
        (uint256 amountOut, uint256 profit) = supervisor.executePrediction(opportunity, signature);

        assertEq(amountOut, 1020e18, "bad output amount");
        assertEq(profit, 20e18, "bad profit");
        assertEq(tokenIn.balanceOf(operator), start + 20e18, "operator net profit mismatch");
    }

    /// @notice Ensures execution reverts when cycle is not profitable.
    function testRevertWhenNoProfit() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 99, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        opportunity.minOutCA = 1;
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.expectRevert(TriangularArbExecutor.NoProfit.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures unauthorized signatures are rejected.
    function testRevertOnInvalidSigner() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        bytes memory signature = _signOpportunity(opportunity, OPERATOR_PK);

        vm.expectRevert(ArbSupervisor.InvalidSignature.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures expired opportunities cannot be executed.
    function testRevertOnDeadlineExpiry() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.warp(opportunity.deadline + 1);
        vm.expectRevert(ArbSupervisor.SignatureExpired.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures digest replay protection blocks second execution.
    function testRevertOnReplay() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);

        vm.expectRevert(ArbSupervisor.ReplayDetected.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures predictionId namespace is isolated from digest replay tracking.
    function testPredictionIdEqualToPriorDigestDoesNotFalseTriggerReplay() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);

        ArbTypes.Opportunity memory first = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        bytes32 firstDigest = _digestForSupervisor(first, address(supervisor));
        bytes memory firstSignature = _signOpportunity(first, SIGNER_PK);

        vm.prank(operator);
        supervisor.executePrediction(first, firstSignature);

        ArbTypes.Opportunity memory second = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        second.nonce += 1;
        second.predictionId = firstDigest;
        bytes memory secondSignature = _signOpportunity(second, SIGNER_PK);

        vm.prank(operator);
        supervisor.executePrediction(second, secondSignature);
    }

    /// @notice Ensures caller/recipient mismatch is blocked when enforcement is enabled.
    function testRevertOnUnauthorizedRecipientCallerMismatch() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), address(0xCAFE), 1000e18, 1e18
        );
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.expectRevert(ArbSupervisor.UnauthorizedCaller.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures non-whitelisted fee tiers are rejected.
    function testRevertOnDisallowedFeeTier() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 102, 100);
        supervisor.setAllowedFeeTier(3000, false);

        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.expectRevert(ArbSupervisor.InvalidFeeTier.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Ensures slippage floor failure from router bubbles up as revert.
    function testRevertOnSlippageMinOutFinal() public {
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 101, 100);
        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, 1000e18, 1e18
        );
        opportunity.minOutCA = 1_020e18;
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.expectRevert(MockSwapRouter.MinOut.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Confirms malicious token callback cannot reenter supervisor execution.
    function testReentrancyAttemptFromMaliciousTokenIsBlocked() public {
        ReentrantToken maliciousIn = new ReentrantToken();
        MockERC20 midA = new MockERC20("MidA", "MA", 18);
        MockERC20 midB = new MockERC20("MidB", "MB", 18);
        MockSwapRouter localRouter = new MockSwapRouter();

        TriangularArbExecutor localExecutor =
            new TriangularArbExecutor(owner, address(localRouter), owner);
        ArbSupervisor localSupervisor = new ArbSupervisor(owner, address(localExecutor), 500_000e18);
        localExecutor.setSupervisor(address(localSupervisor));
        localSupervisor.setSigner(signer, true);

        localRouter.setRate(address(maliciousIn), address(midA), 500, 1, 1);
        localRouter.setRate(address(midA), address(midB), 3000, 1, 1);
        localRouter.setRate(address(midB), address(maliciousIn), 10_000, 102, 100);

        maliciousIn.mint(operator, START_BALANCE);
        vm.prank(operator);
        maliciousIn.approve(address(localExecutor), type(uint256).max);

        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(maliciousIn), address(midA), address(midB), operator, 1000e18, 1e18
        );
        bytes memory signature =
            _signOpportunityForSupervisor(opportunity, SIGNER_PK, address(localSupervisor));
        maliciousIn.configureAttack(address(localSupervisor), opportunity, signature);

        vm.prank(operator);
        localSupervisor.executePrediction(opportunity, signature);

        assertTrue(maliciousIn.attempted(), "reentry not attempted");
        assertFalse(maliciousIn.succeeded(), "reentry unexpectedly succeeded");
    }

    /// @notice Fuzzes digest replay protection across varied amounts/nonces.
    function testFuzz_ReplayProtectionByDigest(uint256 amountIn, uint256 nonce) public {
        amountIn = (amountIn % 10_000e18) + 1e18;
        router.setRate(address(tokenMidB), address(tokenIn), 10_000, 105, 100);

        ArbTypes.Opportunity memory opportunity = _makeOpportunity(
            address(tokenIn), address(tokenMidA), address(tokenMidB), operator, amountIn, 1e18
        );
        opportunity.minProfit = 1;
        opportunity.nonce = nonce;
        bytes memory signature = _signOpportunity(opportunity, SIGNER_PK);

        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);

        vm.expectRevert(ArbSupervisor.ReplayDetected.selector);
        vm.prank(operator);
        supervisor.executePrediction(opportunity, signature);
    }

    /// @notice Builds a baseline opportunity payload used across tests.
    function _makeOpportunity(
        address _tokenIn,
        address _midA,
        address _midB,
        address _recipient,
        uint256 _amountIn,
        uint256 _minProfit
    ) internal view returns (ArbTypes.Opportunity memory opportunity) {
        opportunity = ArbTypes.Opportunity({
            predictionId: keccak256(
                abi.encode(_tokenIn, _midA, _midB, _recipient, _amountIn, block.timestamp)
            ),
            recipient: _recipient,
            tokenIn: _tokenIn,
            tokenMidA: _midA,
            tokenMidB: _midB,
            feeAB: 500,
            feeBC: 3000,
            feeCA: 10_000,
            amountIn: _amountIn,
            minOutAB: _amountIn,
            minOutBC: _amountIn,
            minOutCA: _amountIn,
            minProfit: _minProfit,
            nonce: uint256(keccak256(abi.encodePacked(_recipient, _amountIn, block.timestamp))),
            deadline: block.timestamp + 1 hours
        });
    }

    /// @notice Signs opportunity for the default supervisor.
    function _signOpportunity(ArbTypes.Opportunity memory opportunity, uint256 pk)
        internal
        returns (bytes memory)
    {
        return _signOpportunityForSupervisor(opportunity, pk, address(supervisor));
    }

    /// @notice Signs opportunity for an arbitrary supervisor address.
    /// @dev Mirrors production EIP-712 domain layout for deterministic tests.
    function _signOpportunityForSupervisor(
        ArbTypes.Opportunity memory opportunity,
        uint256 pk,
        address supervisorAddress
    ) internal returns (bytes memory) {
        bytes32 digest = _digestForSupervisor(opportunity, supervisorAddress);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _digestForSupervisor(ArbTypes.Opportunity memory opportunity, address supervisorAddress)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                ArbTypes.OPPORTUNITY_TYPEHASH,
                opportunity.predictionId,
                opportunity.recipient,
                opportunity.tokenIn,
                opportunity.tokenMidA,
                opportunity.tokenMidB,
                opportunity.feeAB,
                opportunity.feeBC,
                opportunity.feeCA,
                opportunity.amountIn,
                opportunity.minOutAB,
                opportunity.minOutBC,
                opportunity.minOutCA,
                opportunity.minProfit,
                opportunity.nonce,
                opportunity.deadline
            )
        );

        bytes32 domainTypeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                domainTypeHash,
                keccak256(bytes("ArbSupervisor")),
                keccak256(bytes("1")),
                block.chainid,
                supervisorAddress
            )
        );

        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
