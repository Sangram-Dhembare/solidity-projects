# Solidity Voting Examples

A small Solidity project for learning how smart contracts can store data and restrict who can change it. It includes a basic voting contract and a poll manager.

## What it does

- `SimpleVoting` creates a fixed list of candidates when deployed and lets each address vote once.
- `PollManager` lets poll creators create polls, open and close voting, and track votes for each poll.
- Both contracts store vote totals on-chain, emit events for votes, and reject invalid candidate numbers and repeat votes.

These are practice examples, not secure or private voting systems. Votes and wallet addresses are public on-chain, and using another wallet address allows another vote.

## Try it in Remix

1. Open [Remix](https://remix.ethereum.org/) and create a Solidity file for either contract.
2. Copy the code from [`contracts/SimpleVoting.sol`](contracts/SimpleVoting.sol) or [`contracts/PollManager.sol`](contracts/PollManager.sol) into the file.
3. In the Solidity Compiler tab, select compiler version `0.8.24` or a compatible `0.8.x` version and compile.
4. In Deploy & Run Transactions, choose `Remix VM` as the environment and select the contract you want to try.
5. For `SimpleVoting`, enter candidate names as a string array, for example `["Alice", "Bob"]`, then deploy. For `PollManager`, deploy with no arguments and call `createPoll` with the same kind of array.
6. With `SimpleVoting`, call `candidateCount` and `candidates` to inspect candidates. For `PollManager`, call `openVoting` with poll ID `0`, then use `candidateCount` and `getCandidate` to inspect its candidates.
7. Call `vote` with a candidate number starting at `0` (`pollId` first for `PollManager`). Try voting again from the same account to see the contract reject it. Switch accounts in Remix to cast another vote.
8. For `PollManager`, call `closeVoting` with the poll ID to stop voting. Check candidate totals again with `getCandidate`.

## Contract details

In both contracts, the candidate list is fixed when the contract is deployed or the poll is created, and candidate numbers start at zero. Each contract records whether an address has voted, and its `VoteCast` event records the voter's address and chosen candidate number.

For `SimpleVoting`, there is no owner or administrator. Anyone can deploy a new poll, and anyone with an eligible address can vote.

For `PollManager`, anyone can create a poll, which starts with voting closed. Only its creator can open or close voting. Polls can be reopened, but an address can still vote only once per poll.
