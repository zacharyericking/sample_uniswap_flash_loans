// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import {ArbTypes} from "../../src/ArbTypes.sol";
import {MockERC20} from "./MockERC20.sol";

interface IArbSupervisor {
    function executePrediction(ArbTypes.Opportunity calldata opportunity, bytes calldata signature)
        external
        returns (uint256, uint256);
}

contract ReentrantToken is MockERC20 {
    IArbSupervisor public supervisor;
    ArbTypes.Opportunity private _opportunity;
    bytes private _signature;
    bool public attackEnabled;
    bool public attempted;
    bool public succeeded;
    bool private _entered;

    constructor() MockERC20("Reentrant", "RNT", 18) {}

    function configureAttack(
        address supervisorAddress,
        ArbTypes.Opportunity calldata opportunity,
        bytes calldata signature
    ) external {
        supervisor = IArbSupervisor(supervisorAddress);
        _opportunity = opportunity;
        _signature = signature;
        attackEnabled = true;
        attempted = false;
        succeeded = false;
        _entered = false;
    }

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
