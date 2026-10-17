# Simple Voting

A small Solidity project for learning how a smart contract can store data and restrict who can change it. The contract lets each wallet address vote once for one of the candidates supplied when the contract is deployed.

## What it does

- Creates a fixed list of candidates when deployed.
- Starts every candidate with zero votes.
- Lets each address cast one vote.
- Keeps vote totals on the blockchain and emits an event for every vote.
- Rejects invalid candidate numbers and repeat votes.

This is a practice project, not a secure or private voting system. Votes and wallet addresses are public on-chain, and using another wallet address allows another vote.

## Try it in Remix

1. Open [Remix](https://remix.ethereum.org/) and create `SimpleVoting.sol`.
2. Copy the contract from [`contracts/SimpleVoting.sol`](contracts/SimpleVoting.sol) into the file.
3. In the Solidity Compiler tab, select compiler version `0.8.24` or a compatible `0.8.x` version and compile.
4. In Deploy & Run Transactions, choose `Remix VM` as the environment and select `SimpleVoting` as the contract.
5. Enter candidate names as a string array, for example `["Alice", "Bob"]`, then deploy.
6. Call `candidateCount` to see how many candidates were added. Call `candidates` with `0` or `1` to see a candidate's name and vote total.
7. Call `vote` with a candidate number, starting at `0`. Try voting again from the same account to see the contract reject it. Switch accounts in Remix to cast another vote.
8. Check the `candidates` values again to see the updated totals.

## Contract details

The candidate list is set at deployment and cannot be changed. Candidate numbers start at zero. The `hasVoted` mapping records whether an address has voted, and the `VoteCast` event records the voter's address and chosen candidate number.

There is no owner or administrator. Anyone can deploy a new poll, and anyone with an eligible address can vote.
