%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.alloc import alloc
from contracts.ships.static_ship.library import StaticShip
from contracts.models.common import Vector2
from contracts.interfaces.icell import Dust, Cell
from contracts.test.standard_cell import StandardCell

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    StandardCell.declare();
    return ();
}

@external
func test_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let grid: Cell* = alloc();
    let cell_class_hash = StandardCell.class_hash();
    assert [grid] = Cell(cell_class_hash, 1, Dust(Vector2(0, 0)), 0);

    let grid_len = 1;
    let ship_id = 1;

    let (next_direction) = StaticShip.move(grid_len, grid, 1);

    // Assert next_direction = Vector2(0, 0)
    assert next_direction.x = 0;
    assert next_direction.y = 0;

    return ();
}
