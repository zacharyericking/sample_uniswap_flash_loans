// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

abstract contract Pausable {
    error Paused();

    bool public isPaused;

    event PauseUpdated(bool isPaused);

    modifier whenNotPaused() {
        if (isPaused) revert Paused();
        _;
    }

    function _setPaused(bool paused_) internal {
        isPaused = paused_;
        emit PauseUpdated(paused_);
    }
}
