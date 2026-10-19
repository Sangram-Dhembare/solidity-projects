// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PollManager {
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
    uint256 public pollCount;

    event PollCreated(uint256 indexed pollId, address indexed creator);
    event VotingOpened(uint256 indexed pollId);
    event VotingClosed(uint256 indexed pollId);
    event VoteCast(uint256 indexed pollId, address indexed voter, uint256 candidateIndex);

    function createPoll(string[] calldata candidateNames) external returns (uint256 pollId) {
        require(candidateNames.length >= 2, "Add at least two candidates");

        pollId = pollCount;
        Poll storage poll = polls[pollId];
        poll.creator = msg.sender;

        for (uint256 i = 0; i < candidateNames.length; i++) {
            require(bytes(candidateNames[i]).length > 0, "Candidate name is empty");
            poll.candidates.push(Candidate({name: candidateNames[i], voteCount: 0}));
        }

        pollCount++;
        emit PollCreated(pollId, msg.sender);
    }

    function openVoting(uint256 pollId) external {
        Poll storage poll = _getPoll(pollId);
        require(msg.sender == poll.creator, "Only the creator can open voting");
        require(!poll.isOpen, "Voting is already open");

        poll.isOpen = true;
        emit VotingOpened(pollId);
    }

    function closeVoting(uint256 pollId) external {
        Poll storage poll = _getPoll(pollId);
        require(msg.sender == poll.creator, "Only the creator can close voting");
        require(poll.isOpen, "Voting is already closed");

        poll.isOpen = false;
        emit VotingClosed(pollId);
    }

    function vote(uint256 pollId, uint256 candidateIndex) external {
        Poll storage poll = _getPoll(pollId);
        require(poll.isOpen, "Voting is not open");
        require(candidateIndex < poll.candidates.length, "Candidate does not exist");
        require(!poll.hasVoted[msg.sender], "You have already voted");

        poll.hasVoted[msg.sender] = true;
        poll.candidates[candidateIndex].voteCount++;

        emit VoteCast(pollId, msg.sender, candidateIndex);
    }

    function getPoll(uint256 pollId) external view returns (address creator, bool isOpen) {
        Poll storage poll = _getPoll(pollId);
        return (poll.creator, poll.isOpen);
    }

    function candidateCount(uint256 pollId) external view returns (uint256) {
        return _getPoll(pollId).candidates.length;
    }

    function getCandidate(
        uint256 pollId,
        uint256 candidateIndex
    ) external view returns (string memory name, uint256 voteCount) {
        Poll storage poll = _getPoll(pollId);
        require(candidateIndex < poll.candidates.length, "Candidate does not exist");

        Candidate storage candidate = poll.candidates[candidateIndex];
        return (candidate.name, candidate.voteCount);
    }

    function hasVoted(uint256 pollId, address voter) external view returns (bool) {
        return _getPoll(pollId).hasVoted[voter];
    }

    function _getPoll(uint256 pollId) private view returns (Poll storage) {
        require(pollId < pollCount, "Poll does not exist");
        return polls[pollId];
    }
}
