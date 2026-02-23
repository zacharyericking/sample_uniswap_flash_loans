// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { ArbTypes } from "../../src/ArbTypes.sol";
import { MockERC20 } from "./MockERC20.sol";

/// @title IArbSupervisor
/// @notice Minimal interface needed by reentrancy attack mock.
interface IArbSupervisor {
    /// @notice Executes signed prediction on supervisor.
    function executePrediction(ArbTypes.Opportunity calldata opportunity, bytes calldata signature)
        external
        returns (uint256, uint256);
}

/// @title ReentrantToken
/// @notice Malicious token mock that attempts callback reentrancy during transferFrom.
/// @dev Supports repository security objective by validating nonReentrant controls in supervisor/executor.
contract ReentrantToken is MockERC20 {
    error ReentrantInvalidAddress();
    error ReentrantInvalidSignature();

    IArbSupervisor public supervisor;
    ArbTypes.Opportunity private _opportunity;
    bytes private _signature;
    bool public attackEnabled;
    bool public attempted;
    bool public succeeded;
    bool private _entered;

    constructor() MockERC20("Reentrant", "RNT", 18) { }

    /// @notice Configures one-shot reentrancy attack payload.
    /// @param supervisorAddress Target supervisor contract.
    /// @param opportunity Signed opportunity payload to replay.
    /// @param signature Signature for opportunity.
    function configureAttack(
        address supervisorAddress,
        ArbTypes.Opportunity calldata opportunity,
        bytes calldata signature
    ) external {
        if (supervisorAddress == address(0)) {
            revert ReentrantInvalidAddress();
        }
        if (signature.length != 65) revert ReentrantInvalidSignature();
        supervisor = IArbSupervisor(supervisorAddress);
        _opportunity = opportunity;
        _signature = signature;
        attackEnabled = true;
        attempted = false;
        succeeded = false;
        _entered = false;
    }

    /// @notice Overrides transferFrom to attempt nested supervisor execution once.
    /// @dev Tracks whether attempt was made and whether it unexpectedly succeeded.
    /// @param from Source account.
    /// @param to Destination account.
    /// @param amount Token amount.
    /// @return `true` on successful transfer behavior.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (attackEnabled && !_entered && address(supervisor) != address(0)) {
            attempted = true;
            _entered = true;
            try supervisor.executePrediction(_opportunity, _signature) returns (uint256, uint256) {
                succeeded = true;
            } catch {
                succeeded = false;
            }
            _entered = false;
        }
        return super.transferFrom(from, to, amount);
    }
}
