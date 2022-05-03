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
    let random_cell = Cell(Dust(TRUE, Vector2(1, -1)), 42)

    assert empty_grid.size = 2
    assert empty_grid.nb_cells = 4
    assert empty_grid.cells[0] = empty_cell
    assert empty_grid.cells[1] = empty_cell
    assert empty_grid.cells[2] = empty_cell
    assert empty_grid.cells[3] = empty_cell
    assert empty_grid.cells[4] = random_cell  # Make sure the memory is free after the last cell

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

@external
func test_grid_set_and_get_dust{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}():
    alloc_locals

    let (current_grid) = grid.create(3)

    let dust1 = Dust(TRUE, Vector2(0, 1))
    let dust2 = Dust(TRUE, Vector2(-1, -1))
    let dust3 = Dust(TRUE, Vector2(0, 0))

    grid.set_dust_at{grid=current_grid}(0, 1, dust1)
    grid.set_dust_at{grid=current_grid}(1, 1, dust2)
    grid.set_dust_at{grid=current_grid}(2, 0, dust3)

    let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

    assert current_grid.size = 3
    assert current_grid.nb_cells = 9

    with_attr error_message("current_grid not updated correctly"):
        assert current_grid.cells[0] = empty_cell
        assert current_grid.cells[1] = empty_cell
        assert current_grid.cells[2] = Cell(dust3, 0)
        assert current_grid.cells[3] = Cell(dust1, 0)
        assert current_grid.cells[4] = Cell(dust2, 0)
        assert current_grid.cells[5] = empty_cell
        assert current_grid.cells[6] = empty_cell
        assert current_grid.cells[7] = empty_cell
        assert current_grid.cells[8] = empty_cell
    end

    grid.clear_dust_at{grid=current_grid}(1, 1)

    with_attr error_message("get_dust_at returns wrong value"):
        let no_dust = Dust(FALSE, Vector2(0, 0))

        let (dust_0_0) = grid.get_dust_at{grid=current_grid}(0, 0)
        assert dust_0_0 = no_dust

        let (dust_0_1) = grid.get_dust_at{grid=current_grid}(0, 1)
        assert dust_0_1 = dust1

        let (dust_1_1) = grid.get_dust_at{grid=current_grid}(1, 1)
        assert dust_1_1 = no_dust

        let (dust_2_0) = grid.get_dust_at{grid=current_grid}(2, 0)
        assert dust_2_0 = dust3
    end

    return ()
end
