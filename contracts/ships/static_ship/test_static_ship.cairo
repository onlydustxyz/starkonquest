%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.alloc import alloc
from contracts.ships.static_ship.library import StaticShip
from contracts.models.common import Vector2
from contracts.libraries.cell import Dust, Cell

@external
func test_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let grid: Cell* = alloc();
    assert [grid] = Cell(1, Dust(Vector2(0, 0)), 0);

    let grid_len = 1;
    let ship_id = 1;

    let (next_direction) = StaticShip.move(grid_len, grid, 1);

    // Assert next_direction = Vector2(0, 0)
    assert next_direction.x = 0;
    assert next_direction.y = 0;

    return ();
}
