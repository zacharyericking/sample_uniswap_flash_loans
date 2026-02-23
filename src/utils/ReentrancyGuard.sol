// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private _status = 1;

    modifier nonReentrant() {
        if (_status == 2) revert Reentrancy();
        _status = 2;
        _;
        _status = 1;
    }
}
