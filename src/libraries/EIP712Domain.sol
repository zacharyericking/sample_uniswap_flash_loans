// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

/// @title EIP712Domain
/// @notice EIP-712 domain separator and digest helpers for typed data signing.
/// @dev Provides chain-aware domain separation for `ArbSupervisor` signature verification.
abstract contract EIP712Domain {
    bytes32 private constant _TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;

    /// @notice Builds and caches an EIP-712 domain separator.
    /// @param name Human-readable name included in signed domain.
    /// @param version Version string included in signed domain.
    constructor(string memory name, string memory version) {
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));
        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
    }

    /// @notice Returns active domain separator, re-building if chain id changed.
    /// @dev Guards signatures against cross-chain replay.
    /// @return Domain separator for current execution chain.
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        }
        return _buildDomainSeparator();
    }

    /// @notice Hashes a typed struct hash into an EIP-712 digest.
    /// @param structHash Hash of typed data struct.
    /// @return Digest used for ECDSA recovery.
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this))
        );
    }
}
