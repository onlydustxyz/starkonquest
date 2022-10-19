%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.models.common import Vector2
from contracts.interfaces.icell import Cell
from contracts.ships.static_ship.library import StaticShip

// ---------
// EXTERNALS
// ---------

@external
func move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_state_len: felt, grid_state: Cell*, ship_id: felt
) -> (new_direction: Vector2) {
    return StaticShip.move(grid_state_len, grid_state, ship_id);
}
