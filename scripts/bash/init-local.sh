#!/bin/bash

set -e

source $( dirname -- "$0" )/utils.sh

# Create Account
echo "Start by re-creating the account"
ACCOUNT_ADDRESS=$(create_account | grep "$CONTRACT_ADDRESS_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Account created at $ACCOUNT_ADDRESS"
mint_for_account $ACCOUNT_ADDRESS

echo ""

# Deploy Ship contract
echo "Deploy Ship Contract..."
BASIC_SHIP_CLASS_HASH=$(declare_contract ./build/basic_ship.json | grep "$CLASS_HASH_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Ship class hash declared at $BASIC_SHIP_CLASS_HASH"
BASIC_SHIP_CONTRACT_ADDRESS=$(deploy_class $BASIC_SHIP_CLASS_HASH | grep "$CONTRACT_ADDRESS_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Ship contract deployed at $BASIC_SHIP_CONTRACT_ADDRESS"

echo ""

# Deploy Battle contract
echo "Deploy Battle Contract..."
BATTLE_CLASS_HASH=$(declare_contract ./build/battle.json | grep "$CLASS_HASH_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Battle class hash declared at $BATTLE_CLASS_HASH"
BATTLE_CONTRACT_ADDRESS=$(deploy_class $BATTLE_CLASS_HASH | grep "$CONTRACT_ADDRESS_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Battle contract deployed at $BATTLE_CONTRACT_ADDRESS"

echo ""

# Deploy Random function contract
echo "Deploy Random Contract..."
RANDOM_CLASS_HASH=$(declare_contract ./build/random.json | grep "$CLASS_HASH_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Random class hash declared at $RANDOM_CLASS_HASH"
RAND_CONTRACT_ADDRESS=$(deploy_class $RANDOM_CLASS_HASH | grep "$CONTRACT_ADDRESS_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Random contract deployed at $RAND_CONTRACT_ADDRESS"

echo ""

# Start battle
echo "Playing game"
function play_game() {
	starknet_local invoke \
	--abi ./build/battle_abi.json \
	--address $BATTLE_CONTRACT_ADDRESS \
	--function play_game \
	--inputs \
		$RAND_CONTRACT_ADDRESS \
		10 \
		20 \
		3 \
		2 \
		$BASIC_SHIP_CONTRACT_ADDRESS 1 1 \
		$BASIC_SHIP_CONTRACT_ADDRESS 7 7
}

GAME_TRANSACTION_HASH=$(play_game | grep "$TRANSACTION_HASH_LABEL" | grep -o '0x[a-f0-9]\+$')
echo "Game is ready at $GAME_TRANSACTION_HASH"

echo "Creating dump"
create_dump
echo "Dump as been updated!"

echo "Loading variables to $ASSETS_DIRECTORY/addresses.sh"
rm -f $ASSETS_DIRECTORY/addresses.sh
touch $ASSETS_DIRECTORY/addresses.sh
echo "BATTLE_CONTRACT_ADDRESS=$BATTLE_CONTRACT_ADDRESS" >> $ASSETS_DIRECTORY/addresses.sh
echo "BASIC_SHIP_CONTRACT_ADDRESS=$BASIC_SHIP_CONTRACT_ADDRESS" >> $ASSETS_DIRECTORY/addresses.sh
echo "RAND_CONTRACT_ADDRESS=$RAND_CONTRACT_ADDRESS" >> $ASSETS_DIRECTORY/addresses.sh
echo "GAME_TRANSACTION_HASH=$GAME_TRANSACTION_HASH" >> $ASSETS_DIRECTORY/addresses.sh

echo "Done!"
