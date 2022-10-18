#!/bin/bash

alias starknet_local='starknet --gateway_url http://127.0.0.1:5050 --feeder_gateway_url http://127.0.0.1:5050'

starknet_local deploy_account
ACCOUNT_ADDRESS=0x777cf2abf06049a04d850a288836d6c2b5f9b108c9e3d890bf0d56915e0d3c4

curl -H "Content-Type: application/json" -X POST --data '{"address":"0x777cf2abf06049a04d850a288836d6c2b5f9b108c9e3d890bf0d56915e0d3c4", "amount":100000000000000000000}' "http://127.0.0.1:5050/mint"

starknet_local declare --contract ./build/basic_ship.json
BASIC_SHIP_CLASS_HASH=0x8193445bec25c9a3274e9b986f0cad865fb006138bb3627de86986ddfe5cae

starknet_local deploy --class_hash $BASIC_SHIP_CLASS_HASH 
BASIC_SHIP_CONTRACT_ADDRESS=0x0121a3cccd42b2522eac8ec048d566f65d95da333fe2a86524e72116cf4e9434

starknet_local declare --contract ./build/battle.json
BATTLE_CLASS_HASH=0x276bda9b367c6032bd85ffd81768a64906dd5f4d878906ccb908dc6f133b0e5

starknet_local deploy --class_hash $BATTLE_CLASS_HASH 
BATTLE_CONTRACT_ADDRESS=0x076e5c430d44ea7306e07feba1bd559cc3d61d677fc65e1282c6dd68e780d668

starknet_local declare --contract ./build/random.json 
RANDOM_CLASS_HASH=0x6e73c7faf69113db5dab5beabddfbfbcf33b60da0ac9e02b1740b4ae1f7c923

starknet_local deploy --class_hash $RANDOM_CLASS_HASH 
RAND_CONTRACT_ADDRESS=0x02e0e047501540958db4e88b64754d5a01293455539c545c16d2c8e8305ddc8c

starknet_local invoke --abi ./build/battle_abi.json --address $BATTLE_CONTRACT_ADDRESS --function play_game --inputs $RAND_CONTRACT_ADDRESS 10 20 3 2 $BASIC_SHIP_CONTRACT_ADDRESS 1 1 $BASIC_SHIP_CONTRACT_ADDRESS 7 7