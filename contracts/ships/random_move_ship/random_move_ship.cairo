%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number

from contracts.models.common import Vector2
from contracts.interfaces.icell import Cell
from contracts.libraries.math_utils import math_utils
from contracts.interfaces.irand import IRandom
from contracts.ships.random_move_ship.library import RandomMoveShip

// -----------
// CONSTRUCTOR
// -----------

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    random_contract_address: felt
) {
    RandomMoveShip.constructor(random_contract_address);
    return ();
}

// ---------
// FUNCTIONS
// ---------

@external
func move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_state_len: felt, grid_state: Cell*, ship_id: felt
) -> (new_direction: Vector2) {
    return RandomMoveShip.move(grid_state_len, grid_state, ship_id);
}
