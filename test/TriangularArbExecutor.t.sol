// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import {Test} from "./utils/Test.sol";
import {ArbTypes} from "../src/ArbTypes.sol";
import {TriangularArbExecutor} from "../src/TriangularArbExecutor.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockSwapRouter} from "./mocks/MockSwapRouter.sol";

contract TriangularArbExecutorTest is Test {
    TriangularArbExecutor internal executor;
    MockSwapRouter internal router;
    MockERC20 internal tokenIn;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal owner;
    address internal supervisor;
    address internal payer;

    function setUp() public {
        owner = address(this);
        supervisor = address(0x1234);
        payer = address(0x7777);

        router = new MockSwapRouter();
        tokenIn = new MockERC20("IN", "IN", 18);
        tokenA = new MockERC20("A", "A", 18);
        tokenB = new MockERC20("B", "B", 18);

        executor = new TriangularArbExecutor(owner, address(router), supervisor);
        tokenIn.mint(payer, 10_000e18);
        vm.prank(payer);
        tokenIn.approve(address(executor), type(uint256).max);
    }

    function testOnlySupervisorCanExecute() public {
        ArbTypes.Opportunity memory opportunity = _opportunity();

        vm.expectRevert(TriangularArbExecutor.NotSupervisor.selector);
        executor.executeOpportunity(opportunity, payer);
    }

    function testPauseBlocksExecution() public {
        executor.setPaused(true);
        ArbTypes.Opportunity memory opportunity = _opportunity();

        vm.expectRevert(bytes4(keccak256("Paused()")));
        vm.prank(supervisor);
        executor.executeOpportunity(opportunity, payer);
    }

    function testRescueTokenOnlyOwner() public {
        tokenIn.mint(address(executor), 100e18);
        vm.expectRevert(bytes4(keccak256("Unauthorized()")));
        vm.prank(address(0xBEEF));
        executor.rescueToken(address(tokenIn), address(0xFEED), 100e18);
    }

    function _opportunity() internal view returns (ArbTypes.Opportunity memory opportunity) {
        opportunity = ArbTypes.Opportunity({
            predictionId: bytes32(uint256(1)),
            recipient: payer,
            tokenIn: address(tokenIn),
            tokenMidA: address(tokenA),
            tokenMidB: address(tokenB),
            feeAB: 500,
            feeBC: 3000,
            feeCA: 10_000,
            amountIn: 100e18,
            minOutAB: 1,
            minOutBC: 1,
            minOutCA: 1,
            minProfit: 1,
            nonce: 1,
            deadline: block.timestamp + 1 hours
        });
    }
}
