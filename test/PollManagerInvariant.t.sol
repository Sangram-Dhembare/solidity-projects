// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { PollManager } from "../src/PollManager.sol";

contract PollManagerVoteHandler is Test {
    PollManager private immutable manager;
    uint256 public acceptedVotes;
    uint256 public firstCandidateVotes;
    uint256 public secondCandidateVotes;

    constructor(
        PollManager pollManager
    ) {
        manager = pollManager;
    }

    function castVote(
        uint256 voterSeed,
        uint256 candidateSeed
    ) external {
        address voter = address(uint160(bound(voterSeed, 1, type(uint160).max)));
        if (manager.hasVoted(0, voter)) return;

        uint256 candidateIndex = candidateSeed % 2;
        vm.prank(voter);
        manager.vote(0, candidateIndex);

        ++acceptedVotes;
        if (candidateIndex == 0) {
            ++firstCandidateVotes;
        } else {
            ++secondCandidateVotes;
        }
    }
}

contract PollManagerInvariantTest is Test {
    PollManager private manager;
    PollManagerVoteHandler private handler;

    function setUp() public {
        manager = new PollManager();
        string[] memory names = new string[](2);
        names[0] = "Alice";
        names[1] = "Bob";
        manager.createPoll(names);
        manager.openVoting(0);

        handler = new PollManagerVoteHandler(manager);
        targetContract(address(handler));
    }

    function invariantTotalCandidateTalliesEqualAcceptedVotes() public view {
        (, uint256 firstCount) = manager.getCandidate(0, 0);
        (, uint256 secondCount) = manager.getCandidate(0, 1);

        assertEq(firstCount, handler.firstCandidateVotes());
        assertEq(secondCount, handler.secondCandidateVotes());
        assertEq(firstCount + secondCount, handler.acceptedVotes());
    }
}
