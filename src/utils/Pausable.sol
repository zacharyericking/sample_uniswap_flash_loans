// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title Pausable
/// @notice Emergency stop primitive for safety-critical execution paths.
/// @dev Used by arbitrage modules to halt execution during incident response.
abstract contract Pausable {
    error Paused();

    bool public isPaused;

    event PauseUpdated(bool isPaused);

    modifier whenNotPaused() {
        if (isPaused) revert Paused();
        _;
    }

    /// @notice Sets paused state for inheriting modules.
    /// @dev Called only through module-specific owner-gated wrappers.
    /// @param paused_ New paused state.
    function _setPaused(bool paused_) internal {
        isPaused = paused_;
        emit PauseUpdated(paused_);
    }
}
