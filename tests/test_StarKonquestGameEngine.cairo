%lang starknet

@contract_interface
namespace StarKonquestGameEngine:
    func create_game():
    end

    func submit_move_intention(
        game_id : felt, player_id: felt, move_intention: felt
    ):
    end

    func submit_move(
        game_id : felt, player_id: felt, move_intention: felt
    ):
    end
end

@external
func test_end_to_end{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_a_address : felt
    %{ 
        ids.contract_a_address = deploy_contract("./src/StarKonquestGameEngine.cairo").contract_address
    %}

    return ()
end
