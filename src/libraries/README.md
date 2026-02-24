# `src/libraries/` Module

Objective: shared low-level safety and cryptographic helpers for supervisor/executor logic.

- `ECDSA.sol`: signer recovery with malleability checks.
- `EIP712Domain.sol`: typed-data domain separator and digest helper.
- `SafeTransferLib.sol`: fail-closed ERC20 transfer/approve wrappers.

These libraries support repository security guarantees around signature integrity and token I/O correctness.
