// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleVoting {
    /// @notice Maximum candidates accepted by this contract.
    uint256 public constant MAX_CANDIDATES = 100;
    /// @notice Maximum byte length for a candidate name.
    uint256 public constant MAX_CANDIDATE_NAME_BYTES = 100;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    /// @notice Candidates are fixed at deployment and use zero-based indexes.
    Candidate[] public candidates;
    /// @notice Whether an address has cast its one vote in this contract.
    mapping(address => bool) public hasVoted;

    /// @notice Emitted when a candidate is added during deployment.
    event CandidateAdded(uint256 indexed candidateIndex, string name);
    /// @notice Emitted after a voter casts a vote.
    event VoteCast(address indexed voter, uint256 indexed candidateIndex);

    error TooFewCandidates(uint256 provided);
    error TooManyCandidates(uint256 provided, uint256 maximum);
    error EmptyCandidateName(uint256 candidateIndex);
    error CandidateNameTooLong(uint256 candidateIndex, uint256 maximumBytes);
    error InvalidCandidateIndex(uint256 candidateIndex, uint256 candidateCount);
    error AlreadyVoted(address voter);

    /// @notice Deploys a fixed candidate list for a one-vote-per-address poll.
    /// @param candidateNames Candidate names, each 1 to 100 bytes.
    constructor(
        string[] memory candidateNames
    ) {
        if (candidateNames.length < 2) {
            revert TooFewCandidates(candidateNames.length);
        }
        if (candidateNames.length > MAX_CANDIDATES) {
            revert TooManyCandidates(candidateNames.length, MAX_CANDIDATES);
        }

        for (uint256 i; i < candidateNames.length; ++i) {
            _validateCandidateName(candidateNames[i], i);
            candidates.push(Candidate({ name: candidateNames[i], voteCount: 0 }));
            emit CandidateAdded(i, candidateNames[i]);
        }
    }

    /// @notice Casts one vote for a candidate.
    /// @param candidateIndex Zero-based candidate index.
    function vote(
        uint256 candidateIndex
    ) external {
        if (candidateIndex >= candidates.length) {
            revert InvalidCandidateIndex(candidateIndex, candidates.length);
        }
        if (hasVoted[msg.sender]) revert AlreadyVoted(msg.sender);

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    /// @notice Returns the number of candidates.
    function candidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function _validateCandidateName(
        string memory name,
        uint256 candidateIndex
    ) private pure {
        uint256 nameLength = bytes(name).length;
        // This helper is called at most MAX_CANDIDATES times by the constructor.
        // forge-lint: disable-next-line(require-revert-in-loop)
        if (nameLength == 0) revert EmptyCandidateName(candidateIndex);
        if (nameLength > MAX_CANDIDATE_NAME_BYTES) {
            // forge-lint: disable-next-line(require-revert-in-loop)
            revert CandidateNameTooLong(candidateIndex, MAX_CANDIDATE_NAME_BYTES);
        }
    }
}
