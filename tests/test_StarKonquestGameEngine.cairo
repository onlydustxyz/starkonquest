%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import get_contract_address

from src.Moves import MOVE_STOP, MOVE_DIR_UP, MOVE_DIR_LEFT

@contract_interface
namespace StarKonquestGameEngine:
    func create_game(game_id : felt) -> (success : felt):
    end

    func add_player(game_id : felt, player_account : felt) -> (player_id : felt):
    end

    func submit_move_intention(game_id : felt, player_id : felt, move_intention : felt):
    end

    func submit_moves(game_id : felt, player_id : felt, moves_len : felt, moves : felt*):
    end
end

const GAME_ID = 13  # because why not
const PLAYER_1_ACCOUNT = 1000  # fake player account address

func _fixture_setup_game{syscall_ptr : felt*, range_check_ptr}() -> (
    game_engine_contract_address : felt, player_1_id : felt
):
    alloc_locals

    local game_engine_contract_address : felt
    %{ ids.game_engine_contract_address = deploy_contract("./src/StarKonquestGameEngine.cairo").contract_address %}

    let (success) = StarKonquestGameEngine.create_game(game_engine_contract_address, GAME_ID)
    assert success = TRUE

    let (player_1_id) = StarKonquestGameEngine.add_player(
        game_engine_contract_address, GAME_ID, PLAYER_1_ACCOUNT
    )

    return (game_engine_contract_address, player_1_id)
end

@external
func test_end_to_end{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local game_engine, player_1_id) = _fixture_setup_game()

    StarKonquestGameEngine.submit_move_intention(
        game_engine,
        GAME_ID,
        player_1_id,
        1946789167956000287632743127838924958220973057940448287389070751584093981930,
    )

    tempvar moves : felt* = new (MOVE_DIR_UP, MOVE_DIR_LEFT, MOVE_STOP)
    StarKonquestGameEngine.submit_moves(game_engine, GAME_ID, player_1_id, 3, moves)

    return ()
end
