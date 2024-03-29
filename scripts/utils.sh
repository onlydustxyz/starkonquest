source ./.env

STARKONQUEST_DIR=$(git rev-parse --show-toplevel)
DEVNET_URL=http://127.0.0.1:5050
ACCOUNT_NAME=starkonquest-local
ACCOUNT_DIRECTORY=$STARKONQUEST_DIR/assets/.starknet_accounts
ASSETS_DIRECTORY=$STARKONQUEST_DIR/assets
CLASS_HASH_LABEL="Contract class hash"
CONTRACT_ADDRESS_LABEL="Contract address"
TRANSACTION_HASH_LABEL="Transaction hash"

function starknet_local() {
	starknet \
		--gateway_url $DEVNET_URL \
		--network alpha-goerli \
		--feeder_gateway_url $DEVNET_URL \
		--account $ACCOUNT_NAME \
		--account_dir $ACCOUNT_DIRECTORY \
		--show_trace \
		"$@"
}

function mint_for_account() {
	curl -H "Content-Type: application/json" -X POST --data "{\"address\":\"$1\", \"amount\":100000000000000000000}" "$DEVNET_URL/mint"
}

function create_account() {
	mkdir -p $ACCOUNT_DIRECTORY
	rm -f $ACCOUNT_DIRECTORY/starknet_open_zeppelin_accounts.json
	touch $ACCOUNT_DIRECTORY/starknet_open_zeppelin_accounts.json
	echo "{}" >> $ACCOUNT_DIRECTORY/starknet_open_zeppelin_accounts.json
	starknet_local deploy_account
}

function declare_contract() {
	COMPILED_CONTRACT_PATH=$1

	starknet_local declare --contract $COMPILED_CONTRACT_PATH
}

function deploy_class() {
	CLASS_HASH=$1

	starknet_local deploy --class_hash $1
}

function create_dump() {
	curl -X POST $DEVNET_URL/dump -d '{ "path": "/tmp/dump.pkl" }' -H "Content-Type: application/json"
}

function _play_game() {
	starknet_local invoke \
	--abi $STARKONQUEST_DIR/build/battle_abi.json \
	--address $BATTLE_CONTRACT_ADDRESS \
	--function play_game \
	--inputs \
		$RAND_CONTRACT_ADDRESS \
		$STANDARD_CELL_CLASS_HASH \
		$GRID_SIZE \
		$TURN_COUNT \
		$MAX_DUST \
		2 \
		$BASIC_SHIP_CONTRACT_ADDRESS 1 1 \
		$BASIC_SHIP_CONTRACT_ADDRESS 7 7
}

function play_game() {
	GAME_TRANSACTION_HASH=$(_play_game | grep "$TRANSACTION_HASH_LABEL" | grep -o '0x[a-f0-9]\+$')
	echo "Game is ready at http://localhost:3000/game/$GAME_TRANSACTION_HASH"
}
