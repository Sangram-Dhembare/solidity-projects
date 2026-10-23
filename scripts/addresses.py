#!/usr/bin/env python3
"""Print the latest Foundry deployment addresses for a chain as Markdown."""

import json
import sys
from pathlib import Path

EXPLORERS = {
    "11155111": "https://sepolia.etherscan.io/address/",
    "84532": "https://sepolia.basescan.org/address/",
}
CONTRACT_NAMES = ("SimpleVoting", "PollManager", "ElectionAnchor", "ContactBook")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 scripts/addresses.py <chain-id>", file=sys.stderr)
        return 2

    chain_id = sys.argv[1]
    path = Path("broadcast/Deploy.s.sol") / chain_id / "run-latest.json"
    if not path.is_file():
        print(f"No latest deployment found: {path}", file=sys.stderr)
        return 1

    with path.open(encoding="utf-8") as deployment_file:
        deployment = json.load(deployment_file)

    contracts = {}
    for transaction in deployment.get("transactions", []):
        if transaction.get("transactionType") != "CREATE":
            continue
        name = transaction.get("contractName")
        address = transaction.get("contractAddress")
        if name in CONTRACT_NAMES and address:
            contracts[name] = address

    explorer = EXPLORERS.get(chain_id)
    print("| Contract | Address |")
    print("| --- | --- |")
    for name in CONTRACT_NAMES:
        address = contracts.get(name)
        if address is None:
            print(f"| {name} | Not found in latest deployment |")
        elif explorer:
            print(f"| {name} | [{address}]({explorer}{address}) |")
        else:
            print(f"| {name} | `{address}` (chain {chain_id}) |")

    return 0 if len(contracts) == len(CONTRACT_NAMES) else 1


if __name__ == "__main__":
    raise SystemExit(main())
