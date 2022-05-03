%lang starknet

from contracts.libraries.grid import grid_manip
from contracts.models.common import Cell, Vector2, Dust

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le

@external
func test_grid_create_init_with_empty_cell{range_check_ptr}():
    let (empty_grid) = grid_manip.create(2)
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
func test_grid_create_different_arrays{range_check_ptr}():
    alloc_locals

    let (empty_grid) = grid_manip.create(2)
    local grid1 : grid_manip.Grid = empty_grid
    local grid2 : grid_manip.Grid = empty_grid

    %{ assert ids.grid1.cells != ids.grid2.cells, f"a = {ids.grid1.cells} is equal to {ids.grid2.cells}" %}

    return ()
end

@external
func test_grid_set_and_get_dust{range_check_ptr}():
    let (grid) = grid_manip.create(3)

    with grid:
        let dust1 = Dust(TRUE, Vector2(0, 1))
        let dust2 = Dust(TRUE, Vector2(-1, -1))
        let dust3 = Dust(TRUE, Vector2(0, 0))

        grid_manip.set_dust_at(0, 1, dust1)
        grid_manip.set_dust_at(1, 1, dust2)
        grid_manip.set_dust_at(2, 0, dust3)

        let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

        with_attr error_message("grid not updated correctly"):
            assert grid.cells[0] = empty_cell
            assert grid.cells[1] = empty_cell
            assert grid.cells[2] = Cell(dust3, 0)
            assert grid.cells[3] = Cell(dust1, 0)
            assert grid.cells[4] = Cell(dust2, 0)
            assert grid.cells[5] = empty_cell
            assert grid.cells[6] = empty_cell
            assert grid.cells[7] = empty_cell
            assert grid.cells[8] = empty_cell
        end

        grid_manip.clear_dust_at(1, 1)

        with_attr error_message("get_dust_at returns wrong value"):
            let no_dust = Dust(FALSE, Vector2(0, 0))

            let (dust_0_0) = grid_manip.get_dust_at(0, 0)
            assert dust_0_0 = no_dust

            let (dust_0_1) = grid_manip.get_dust_at(0, 1)
            assert dust_0_1 = dust1

            let (dust_1_1) = grid_manip.get_dust_at(1, 1)
            assert dust_1_1 = no_dust

            let (dust_2_0) = grid_manip.get_dust_at(2, 0)
            assert dust_2_0 = dust3
        end
    end

    return ()
end

@external
func test_grid_set_and_get_ship{range_check_ptr}():
    let (grid) = grid_manip.create(3)
    with grid:
        grid_manip.set_ship_at(0, 1, 1)
        grid_manip.set_ship_at(1, 1, 2)
        grid_manip.set_ship_at(2, 0, 3)

        let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

        with_attr error_message("grid not updated correctly"):
            assert grid.cells[0] = empty_cell
            assert grid.cells[1] = empty_cell
            assert grid.cells[2] = Cell(Dust(FALSE, Vector2(0, 0)), 3)
            assert grid.cells[3] = Cell(Dust(FALSE, Vector2(0, 0)), 1)
            assert grid.cells[4] = Cell(Dust(FALSE, Vector2(0, 0)), 2)
            assert grid.cells[5] = empty_cell
            assert grid.cells[6] = empty_cell
            assert grid.cells[7] = empty_cell
            assert grid.cells[8] = empty_cell
        end

        grid_manip.clear_ship_at(1, 1)

        with_attr error_message("get_ship_at returns wrong value"):
            let (ship_0_0) = grid_manip.get_ship_at(0, 0)
            assert ship_0_0 = 0

            let (ship_0_1) = grid_manip.get_ship_at(0, 1)
            assert ship_0_1 = 1

            let (ship_1_1) = grid_manip.get_ship_at(1, 1)
            assert ship_1_1 = 0

            let (ship_2_0) = grid_manip.get_ship_at(2, 0)
            assert ship_2_0 = 3
        end
    end

    return ()
end

@external
func test_grid_set_clear_should_preserve_other_objects{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        let dust1 = Dust(TRUE, Vector2(1, 1))
        let dust2 = Dust(TRUE, Vector2(-1, -1))

        let ship1 = 11
        let ship2 = 22

        grid_manip.set_dust_at(0, 0, dust1)
        grid_manip.set_ship_at(0, 0, ship1)

        grid_manip.set_dust_at(1, 1, dust2)
        grid_manip.set_ship_at(1, 1, ship2)

        with_attr error_message("grid not updated correctly"):
            assert grid.cells[0] = Cell(dust1, ship1)
            assert grid.cells[3] = Cell(dust2, ship2)
        end

        grid_manip.clear_ship_at(0, 0)
        grid_manip.clear_dust_at(1, 1)

        with_attr error_message("clear_ship/dust removed other objects"):
            let no_dust = Dust(FALSE, Vector2(0, 0))
            let no_ship = 0

            assert grid.cells[0] = Cell(dust1, no_ship)
            assert grid.cells[3] = Cell(no_dust, ship2)
        end
    end

    return ()
end

@external
func test_grid_set_dust_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.set_dust_at(0, 3, Dust(TRUE, Vector2(1, 1)))
    end

    return ()
end

@external
func test_grid_get_dust_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.get_dust_at(0, 3)
    end

    return ()
end

@external
func test_grid_clear_dust_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.clear_dust_at(0, 3)
    end

    return ()
end

@external
func test_grid_set_ship_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.set_ship_at(0, 3, 1)
    end

    return ()
end

@external
func test_grid_get_ship_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.get_ship_at(0, 3)
    end

    return ()
end

@external
func test_grid_clear_ship_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.clear_ship_at(0, 3)
    end

    return ()
end
