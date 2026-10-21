// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { SimpleVoting } from "../src/SimpleVoting.sol";

contract SimpleVotingTest is Test {
    SimpleVoting private voting;

    function setUp() public {
        voting = new SimpleVoting(_twoCandidates());
    }

    function testConstructorEmitsCandidateEvents() public {
        vm.expectEmit(true, false, false, true);
        emit SimpleVoting.CandidateAdded(0, "Alice");
        vm.expectEmit(true, false, false, true);
        emit SimpleVoting.CandidateAdded(1, "Bob");

        new SimpleVoting(_twoCandidates());
    }

    function testConstructorRejectsFewerThanTwoCandidates() public {
        string[] memory names = new string[](1);
        names[0] = "Alice";

        vm.expectRevert(abi.encodeWithSelector(SimpleVoting.TooFewCandidates.selector, 1));
        new SimpleVoting(names);
    }

    function testConstructorRejectsTooManyCandidates() public {
        string[] memory names = new string[](voting.MAX_CANDIDATES() + 1);
        for (uint256 i; i < names.length; ++i) {
            names[i] = "Candidate";
        }

        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVoting.TooManyCandidates.selector, names.length, voting.MAX_CANDIDATES()
            )
        );
        new SimpleVoting(names);
    }

    function testConstructorRejectsEmptyCandidateName() public {
        string[] memory names = _twoCandidates();
        names[1] = "";

        vm.expectRevert(abi.encodeWithSelector(SimpleVoting.EmptyCandidateName.selector, 1));
        new SimpleVoting(names);
    }

    function testConstructorRejectsOverlongCandidateName() public {
        string[] memory names = _twoCandidates();
        names[1] = _repeat("a", voting.MAX_CANDIDATE_NAME_BYTES() + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVoting.CandidateNameTooLong.selector, 1, voting.MAX_CANDIDATE_NAME_BYTES()
            )
        );
        new SimpleVoting(names);
    }

    function testCandidateViewsReturnFixedCandidateData() public view {
        assertEq(voting.candidateCount(), 2);
        (string memory name, uint256 voteCount) = voting.candidates(1);
        assertEq(name, "Bob");
        assertEq(voteCount, 0);
    }

    function testVoteUpdatesTallyAndVoterStateAndEmitsEvent() public {
        address voter = address(0xA11CE);
        vm.expectEmit(true, true, false, true, address(voting));
        emit SimpleVoting.VoteCast(voter, 1);

        vm.prank(voter);
        voting.vote(1);

        assertTrue(voting.hasVoted(voter));
        (, uint256 voteCount) = voting.candidates(1);
        assertEq(voteCount, 1);
    }

    function testVoteRejectsInvalidCandidateIndex() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleVoting.InvalidCandidateIndex.selector, 2, 2));
        voting.vote(2);
    }

    function testVoteRejectsSecondVoteFromSameAddress() public {
        address voter = address(0xA11CE);
        vm.prank(voter);
        voting.vote(0);

        vm.expectRevert(abi.encodeWithSelector(SimpleVoting.AlreadyVoted.selector, voter));
        vm.prank(voter);
        voting.vote(1);
    }

    function testFuzzVoteCountsValidCandidateIndex(
        uint256 rawVoter,
        uint256 rawCandidateIndex
    ) public {
        address voter = address(uint160(bound(rawVoter, 1, type(uint160).max)));
        uint256 candidateIndex = bound(rawCandidateIndex, 0, 1);

        vm.prank(voter);
        voting.vote(candidateIndex);

        assertTrue(voting.hasVoted(voter));
        (, uint256 voteCount) = voting.candidates(candidateIndex);
        assertEq(voteCount, 1);
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
