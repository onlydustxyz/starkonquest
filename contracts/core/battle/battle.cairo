// Declare this file as a StarkNet contract.
%lang starknet

from contracts.core.battle.library import battle
from contracts.models.common import ShipInit

// ------------------
// EXTERNAL FUNCTIONS
// ------------------

@external
func play_game{syscall_ptr: felt*, range_check_ptr}(
    rand_contract_address: felt,
    cell_class_hash: felt,
    size: felt,
    turn_count: felt,
    max_dust: felt,
    ships_len: felt,
    ships: ShipInit*,
) -> (scores_len: felt, scores: felt*) {
    return battle.play_game(
        rand_contract_address, cell_class_hash, size, turn_count, max_dust, ships_len, ships
    );
}
