%lang starknet

from contracts.libraries.grid import grid
from contracts.models.common import Cell, Vector2, Dust

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

@external
func test_grid_create_init_with_empty_cell{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}():
    alloc_locals

    let (empty_grid) = grid.create(2)
    let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

    assert empty_grid.size = 2
    assert empty_grid.nb_cells = 4
    assert empty_grid.cells[0] = empty_cell
    assert empty_grid.cells[1] = empty_cell
    assert empty_grid.cells[2] = empty_cell
    assert empty_grid.cells[3] = empty_cell
    assert empty_grid.cells[4] = empty_cell

    return ()
end

@external
func test_grid_create_different_arrays{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}():
    alloc_locals

    let (empty_grid) = grid.create(2)
    local grid1 : grid.Grid = empty_grid
    local grid2 : grid.Grid = empty_grid

    %{ assert ids.grid1.cells != ids.grid2.cells, f"a = {ids.grid1.cells} is equal to {ids.grid2.cells}" %}

    return ()
end
