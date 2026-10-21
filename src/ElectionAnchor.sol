// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ElectionAnchor
/// @notice Records the first on-chain claim for a SHA-256 election config digest.
contract ElectionAnchor {
    /// @notice Whether a digest has been anchored.
    mapping(bytes32 digest => bool anchored) public isAnchored;
    /// @notice Address that first anchored a digest.
    mapping(bytes32 digest => address organizer) public organizerOf;
    /// @notice Block timestamp when the digest was anchored.
    mapping(bytes32 digest => uint256 timestamp) public anchoredAt;

    /// @notice Emitted when a config digest is first anchored.
    event ConfigAnchored(bytes32 indexed digest, address indexed organizer, uint256 timestamp);

    error ZeroDigest();
    error DigestAlreadyAnchored(bytes32 digest);

    /// @notice Anchors a precomputed SHA-256 digest of a canonical election config.
    /// @dev Any address may make the first claim; this does not validate the config or organizer.
    /// @param digest The 32-byte SHA-256 digest produced by the application.
    function anchor(
        bytes32 digest
    ) external {
        if (digest == bytes32(0)) revert ZeroDigest();
        if (isAnchored[digest]) revert DigestAlreadyAnchored(digest);

        isAnchored[digest] = true;
        organizerOf[digest] = msg.sender;
        anchoredAt[digest] = block.timestamp;

        emit ConfigAnchored(digest, msg.sender, block.timestamp);
    }

    /// @notice Checks whether a digest has been anchored.
    /// @param digest The config digest to verify.
    /// @return True if this contract has recorded the digest.
    function verify(
        bytes32 digest
    ) external view returns (bool) {
        return isAnchored[digest];
    }
}
