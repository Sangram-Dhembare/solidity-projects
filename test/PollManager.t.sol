// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { PollManager } from "../src/PollManager.sol";

contract PollManagerTest is Test {
    PollManager private manager;
    uint256 private pollId;

    function setUp() public {
        manager = new PollManager();
        pollId = manager.createPoll(_twoCandidates());
    }

    function testCreatePollSetsCreatorAndCandidateList() public view {
        (address creator, bool isOpen) = manager.getPoll(pollId);
        assertEq(creator, address(this));
        assertFalse(isOpen);
        assertEq(manager.pollCount(), 1);
        assertEq(manager.candidateCount(pollId), 2);

        (string memory name, uint256 voteCount) = manager.getCandidate(pollId, 1);
        assertEq(name, "Bob");
        assertEq(voteCount, 0);
        assertFalse(manager.hasVoted(pollId, address(this)));
    }

    function testCreatePollEmitsCandidateAndPollEvents() public {
        vm.expectEmit(true, true, false, true);
        emit PollManager.CandidateAdded(1, 0, "Alice");
        vm.expectEmit(true, true, false, true);
        emit PollManager.CandidateAdded(1, 1, "Bob");
        vm.expectEmit(true, true, false, false);
        emit PollManager.PollCreated(1, address(this));

        manager.createPoll(_twoCandidates());
    }

    function testCreatePollRejectsFewerThanTwoCandidates() public {
        string[] memory names = new string[](1);
        names[0] = "Alice";

        vm.expectRevert(abi.encodeWithSelector(PollManager.TooFewCandidates.selector, 1));
        manager.createPoll(names);
    }

    function testCreatePollRejectsTooManyCandidates() public {
        string[] memory names = new string[](manager.MAX_CANDIDATES() + 1);
        for (uint256 i; i < names.length; ++i) {
            names[i] = "Candidate";
        }

        vm.expectRevert(
            abi.encodeWithSelector(
                PollManager.TooManyCandidates.selector, names.length, manager.MAX_CANDIDATES()
            )
        );
        manager.createPoll(names);
    }

    function testCreatePollRejectsEmptyCandidateName() public {
        string[] memory names = _twoCandidates();
        names[1] = "";

        vm.expectRevert(abi.encodeWithSelector(PollManager.EmptyCandidateName.selector, 1));
        manager.createPoll(names);
    }

    function testCreatePollRejectsOverlongCandidateName() public {
        string[] memory names = _twoCandidates();
        names[0] = _repeat("a", manager.MAX_CANDIDATE_NAME_BYTES() + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                PollManager.CandidateNameTooLong.selector, 0, manager.MAX_CANDIDATE_NAME_BYTES()
            )
        );
        manager.createPoll(names);
    }

    function testOpenVotingIsCreatorOnlyAndEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit PollManager.VotingOpened(pollId);

        manager.openVoting(pollId);
        (, bool isOpen) = manager.getPoll(pollId);
        assertTrue(isOpen);
    }

    function testOpenVotingRejectsNonCreator() public {
        address other = address(0xBEEF);
        vm.expectRevert(abi.encodeWithSelector(PollManager.NotPollCreator.selector, other, pollId));
        vm.prank(other);
        manager.openVoting(pollId);
    }

    function testOpenVotingRejectsAlreadyOpenPoll() public {
        manager.openVoting(pollId);

        vm.expectRevert(abi.encodeWithSelector(PollManager.VotingAlreadyOpen.selector, pollId));
        manager.openVoting(pollId);
    }

    function testCloseVotingIsCreatorOnlyAndEmitsEvent() public {
        manager.openVoting(pollId);
        vm.expectEmit(true, false, false, false);
        emit PollManager.VotingClosed(pollId);

        manager.closeVoting(pollId);
        (, bool isOpen) = manager.getPoll(pollId);
        assertFalse(isOpen);
    }

    function testCloseVotingRejectsNonCreator() public {
        manager.openVoting(pollId);
        address other = address(0xBEEF);
        vm.expectRevert(abi.encodeWithSelector(PollManager.NotPollCreator.selector, other, pollId));
        vm.prank(other);
        manager.closeVoting(pollId);
    }

    function testCloseVotingRejectsAlreadyClosedPoll() public {
        vm.expectRevert(abi.encodeWithSelector(PollManager.VotingNotOpen.selector, pollId));
        manager.closeVoting(pollId);
    }

    function testVoteUpdatesStateAndEmitsEvent() public {
        manager.openVoting(pollId);
        address voter = address(0xA11CE);
        vm.expectEmit(true, true, false, true);
        emit PollManager.VoteCast(pollId, voter, 1);

        vm.prank(voter);
        manager.vote(pollId, 1);

        assertTrue(manager.hasVoted(pollId, voter));
        (, uint256 voteCount) = manager.getCandidate(pollId, 1);
        assertEq(voteCount, 1);
    }

    function testVoteRejectsWhenVotingIsClosed() public {
        vm.expectRevert(abi.encodeWithSelector(PollManager.VotingNotOpen.selector, pollId));
        manager.vote(pollId, 0);
    }

    function testVoteRejectsInvalidCandidateIndex() public {
        manager.openVoting(pollId);
        vm.expectRevert(abi.encodeWithSelector(PollManager.InvalidCandidateIndex.selector, 2, 2));
        manager.vote(pollId, 2);
    }

    function testVoteRejectsSecondVoteFromSameAddress() public {
        manager.openVoting(pollId);
        address voter = address(0xA11CE);
        vm.prank(voter);
        manager.vote(pollId, 0);

        vm.expectRevert(abi.encodeWithSelector(PollManager.AlreadyVoted.selector, voter, pollId));
        vm.prank(voter);
        manager.vote(pollId, 1);
    }

    function testCandidateGetterRejectsInvalidIndex() public {
        vm.expectRevert(abi.encodeWithSelector(PollManager.InvalidCandidateIndex.selector, 2, 2));
        manager.getCandidate(pollId, 2);
    }

    function testPollViewsRejectUnknownPoll() public {
        uint256 unknownPollId = manager.pollCount();
        bytes memory expectedError =
            abi.encodeWithSelector(PollManager.PollDoesNotExist.selector, unknownPollId);

        vm.expectRevert(expectedError);
        manager.getPoll(unknownPollId);
        vm.expectRevert(expectedError);
        manager.candidateCount(unknownPollId);
        vm.expectRevert(expectedError);
        manager.getCandidate(unknownPollId, 0);
        vm.expectRevert(expectedError);
        manager.hasVoted(unknownPollId, address(this));
        vm.expectRevert(expectedError);
        manager.openVoting(unknownPollId);
        vm.expectRevert(expectedError);
        manager.closeVoting(unknownPollId);
        vm.expectRevert(expectedError);
        manager.vote(unknownPollId, 0);
    }

    function testFuzzVoteCountsEqualDistinctVotes(
        uint256 rawVoteCount
    ) public {
        uint256 voteCount = bound(rawVoteCount, 1, 20);
        manager.openVoting(pollId);

        for (uint256 i; i < voteCount; ++i) {
            address voter = address(uint160(i + 1));
            uint256 candidateIndex = uint256(keccak256(abi.encode(i))) % 2;
            vm.prank(voter);
            manager.vote(pollId, candidateIndex);
            assertTrue(manager.hasVoted(pollId, voter));
        }

        (, uint256 firstCount) = manager.getCandidate(pollId, 0);
        (, uint256 secondCount) = manager.getCandidate(pollId, 1);
        assertEq(firstCount + secondCount, voteCount);
    }

    function _twoCandidates() private pure returns (string[] memory names) {
        names = new string[](2);
        names[0] = "Alice";
        names[1] = "Bob";
    }

    function _repeat(
        string memory value,
        uint256 count
    ) private pure returns (string memory) {
        bytes memory result = new bytes(count);
        bytes memory source = bytes(value);
        for (uint256 i; i < count; ++i) {
            result[i] = source[i % source.length];
        }
        return string(result);
    }
}
