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

    assert empty_grid[0] = empty_cell
    assert empty_grid[1] = empty_cell
    assert empty_grid[2] = empty_cell
    assert empty_grid[3] = empty_cell
    assert empty_grid[4] = empty_cell

    return ()
end

@external
func test_grid_create_different_arrays{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}():
    alloc_locals

    let (empty_grid) = Grid.create(2)
    local grid1 : Cell* = empty_grid
    local grid2 : Cell* = empty_grid

    %{ assert ids.grid1 != ids.grid2, f"a = {ids.grid1} is equal to {ids.grid2}" %}

    return ()
end
