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

    func submit_move_intention(game_id : felt, move_intention : felt):
    end

    func submit_moves(game_id : felt, moves_len : felt, moves : felt*):
    end
end

@external
func test_end_to_end{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_a_address : felt
    %{ ids.contract_a_address = deploy_contract("./src/StarKonquestGameEngine.cairo").contract_address %}

    let (contract_address) = get_contract_address()
    local game_id = 11
    let (success) = StarKonquestGameEngine.create_game(contract_a_address, game_id)
    assert success = TRUE

    local player1_account = contract_address
    let (local player_id) = StarKonquestGameEngine.add_player(
        contract_a_address, game_id, player1_account
    )

    StarKonquestGameEngine.submit_move_intention(
        contract_a_address,
        game_id,
        1946789167956000287632743127838924958220973057940448287389070751584093981930,
    )

    tempvar moves : felt* = new (MOVE_DIR_UP, MOVE_DIR_LEFT, MOVE_STOP)
    StarKonquestGameEngine.submit_moves(contract_a_address, game_id, 3, moves)

    return ()
end
