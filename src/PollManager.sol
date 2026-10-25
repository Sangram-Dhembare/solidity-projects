// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PollManager {
    /// @notice Maximum candidates accepted for a poll.
    uint256 public constant MAX_CANDIDATES = 100;
    /// @notice Maximum byte length for a candidate name.
    uint256 public constant MAX_CANDIDATE_NAME_BYTES = 100;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct Poll {
        address creator;
        bool isOpen;
        Candidate[] candidates;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Poll) private polls;
    /// @notice Number of polls created; IDs start at zero.
    uint256 public pollCount;

    /// @notice Emitted after a poll and its fixed candidate list are created.
    event PollCreated(uint256 indexed pollId, address indexed creator);
    /// @notice Emitted when a candidate is added to a poll.
    event CandidateAdded(uint256 indexed pollId, uint256 indexed candidateIndex, string name);
    /// @notice Emitted when voting is opened for a poll.
    event VotingOpened(uint256 indexed pollId);
    /// @notice Emitted when voting is closed for a poll.
    event VotingClosed(uint256 indexed pollId);
    /// @notice Emitted after a voter casts a vote.
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 candidateIndex);

    error TooFewCandidates(uint256 provided);
    error TooManyCandidates(uint256 provided, uint256 maximum);
    error EmptyCandidateName(uint256 candidateIndex);
    error CandidateNameTooLong(uint256 candidateIndex, uint256 maximumBytes);
    error PollDoesNotExist(uint256 pollId);
    error NotPollCreator(address caller, uint256 pollId);
    error VotingAlreadyOpen(uint256 pollId);
    error VotingNotOpen(uint256 pollId);
    error InvalidCandidateIndex(uint256 candidateIndex, uint256 candidateCount);
    error AlreadyVoted(address voter, uint256 pollId);

    /// @notice Creates a poll with a fixed candidate list. Voting starts closed.
    /// @param candidateNames Candidate names, each 1 to 100 bytes.
    /// @return pollId The new poll's zero-based identifier.
    function createPoll(
        string[] calldata candidateNames
    ) external returns (uint256 pollId) {
        if (candidateNames.length < 2) {
            revert TooFewCandidates(candidateNames.length);
        }
        if (candidateNames.length > MAX_CANDIDATES) {
            revert TooManyCandidates(candidateNames.length, MAX_CANDIDATES);
        }

        pollId = pollCount;
        Poll storage poll = polls[pollId];
        poll.creator = msg.sender;

        for (uint256 i; i < candidateNames.length; ++i) {
            _validateCandidateName(candidateNames[i], i);
            poll.candidates.push(Candidate({ name: candidateNames[i], voteCount: 0 }));
            emit CandidateAdded(pollId, i, candidateNames[i]);
        }

        pollCount++;
        emit PollCreated(pollId, msg.sender);
    }

    /// @notice Opens voting for a poll. Only its creator may call this function.
    /// @param pollId The poll to open.
    function openVoting(
        uint256 pollId
    ) external {
        Poll storage poll = _getPoll(pollId);
        if (msg.sender != poll.creator) revert NotPollCreator(msg.sender, pollId);
        if (poll.isOpen) revert VotingAlreadyOpen(pollId);

        poll.isOpen = true;
        emit VotingOpened(pollId);
    }

    /// @notice Closes voting for a poll. Only its creator may call this function.
    /// @param pollId The poll to close.
    function closeVoting(
        uint256 pollId
    ) external {
        Poll storage poll = _getPoll(pollId);
        if (msg.sender != poll.creator) revert NotPollCreator(msg.sender, pollId);
        if (!poll.isOpen) revert VotingNotOpen(pollId);

        poll.isOpen = false;
        emit VotingClosed(pollId);
    }

    /// @notice Casts one vote per address while the poll is open.
    /// @param pollId The poll to vote in.
    /// @param candidateIndex Zero-based candidate index.
    function vote(
        uint256 pollId,
        uint256 candidateIndex
    ) external {
        Poll storage poll = _getPoll(pollId);
        if (!poll.isOpen) revert VotingNotOpen(pollId);
        if (candidateIndex >= poll.candidates.length) {
            revert InvalidCandidateIndex(candidateIndex, poll.candidates.length);
        }
        if (poll.hasVoted[msg.sender]) revert AlreadyVoted(msg.sender, pollId);

        poll.hasVoted[msg.sender] = true;
        poll.candidates[candidateIndex].voteCount++;

        emit VoteCast(pollId, msg.sender, candidateIndex);
    }

    /// @notice Returns a poll's creator and current voting status.
    /// @param pollId The poll to inspect.
    function getPoll(
        uint256 pollId
    ) external view returns (address creator, bool isOpen) {
        Poll storage poll = _getPoll(pollId);
        return (poll.creator, poll.isOpen);
    }

    /// @notice Returns the number of candidates in a poll.
    /// @param pollId The poll to inspect.
    function candidateCount(
        uint256 pollId
    ) external view returns (uint256) {
        return _getPoll(pollId).candidates.length;
    }

    /// @notice Returns a candidate's name and vote count.
    /// @param pollId The poll to inspect.
    /// @param candidateIndex Zero-based candidate index.
    function getCandidate(
        uint256 pollId,
        uint256 candidateIndex
    ) external view returns (string memory name, uint256 voteCount) {
        Poll storage poll = _getPoll(pollId);
        if (candidateIndex >= poll.candidates.length) {
            revert InvalidCandidateIndex(candidateIndex, poll.candidates.length);
        }

        Candidate storage candidate = poll.candidates[candidateIndex];
        return (candidate.name, candidate.voteCount);
    }

    /// @notice Returns all candidates and their current vote counts for a poll.
    /// @param pollId The poll to inspect.
    function getCandidates(
        uint256 pollId
    ) external view returns (Candidate[] memory) {
        return _getPoll(pollId).candidates;
    }

    /// @notice Returns whether an address has voted in a poll.
    /// @param pollId The poll to inspect.
    /// @param voter The address to check.
    function hasVoted(
        uint256 pollId,
        address voter
    ) external view returns (bool) {
        return _getPoll(pollId).hasVoted[voter];
    }

    function _getPoll(
        uint256 pollId
    ) private view returns (Poll storage) {
        if (pollId >= pollCount) revert PollDoesNotExist(pollId);
        return polls[pollId];
    }

    function _validateCandidateName(
        string memory name,
        uint256 candidateIndex
    ) private pure {
        uint256 nameLength = bytes(name).length;
        // This helper is called at most MAX_CANDIDATES times by createPoll.
        // forge-lint: disable-next-line(require-revert-in-loop)
        if (nameLength == 0) revert EmptyCandidateName(candidateIndex);
        if (nameLength > MAX_CANDIDATE_NAME_BYTES) {
            // forge-lint: disable-next-line(require-revert-in-loop)
            revert CandidateNameTooLong(candidateIndex, MAX_CANDIDATE_NAME_BYTES);
        }
    }
}
