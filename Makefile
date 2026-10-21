ANVIL_SENDER ?= 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ACCOUNT ?=
CHAIN_ID ?= 11155111

.PHONY: build test coverage fmt anvil deploy-local deploy-sepolia addresses

build:
	forge build

test:
	forge test

coverage:
	forge coverage

fmt:
	forge fmt

anvil:
	anvil --host 127.0.0.1 --chain-id 31337

deploy-local:
	forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --unlocked --sender $(ANVIL_SENDER)

deploy-sepolia:
	@test -n "$(ACCOUNT)" || (echo "Set ACCOUNT to a Foundry keystore name" >&2; exit 1)
	forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --account "$(ACCOUNT)" --verify

addresses:
	python3 scripts/addresses.py "$(CHAIN_ID)"
