%lang starknet

from contracts.libraries.grid import grid_manip
from contracts.models.common import Cell, Vector2, Dust, Grid

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

        with_attr error_message("is_cell_occupied broken"):
            let (cell_0_0_occupied) = grid_manip.is_cell_occupied(0, 0)
            assert cell_0_0_occupied = 0

            let (cell_0_1_occupied) = grid_manip.is_cell_occupied(0, 1)
            assert cell_0_1_occupied = 1

            let (cell_1_1_occupied) = grid_manip.is_cell_occupied(1, 1)
            assert cell_1_1_occupied = 1

            let (cell_2_0_occupied) = grid_manip.is_cell_occupied(2, 0)
            assert cell_2_0_occupied = 1
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

        with_attr error_message("is_cell_occupied broken"):
            let (cell_0_0_occupied) = grid_manip.is_cell_occupied(0, 0)
            assert cell_0_0_occupied = 0

            let (cell_0_1_occupied) = grid_manip.is_cell_occupied(0, 1)
            assert cell_0_1_occupied = 1

            let (cell_1_1_occupied) = grid_manip.is_cell_occupied(1, 1)
            assert cell_1_1_occupied = 1

            let (cell_2_0_occupied) = grid_manip.is_cell_occupied(2, 0)
            assert cell_2_0_occupied = 1
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

        with_attr error_message("is_cell_occupied broken"):
            let (cell_0_0_occupied) = grid_manip.is_cell_occupied(0, 0)
            assert cell_0_0_occupied = 1

            let (cell_0_1_occupied) = grid_manip.is_cell_occupied(0, 1)
            assert cell_0_1_occupied = 0

            let (cell_1_0_occupied) = grid_manip.is_cell_occupied(1, 0)
            assert cell_1_0_occupied = 0

            let (cell_1_1_occupied) = grid_manip.is_cell_occupied(1, 1)
            assert cell_1_1_occupied = 1
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

@external
func test_generate_random_position_on_border{range_check_ptr}():
    alloc_locals

    let (grid) = grid_manip.create(10)

    local r1
    local r2
    local r3
    %{
        import random
        ids.r1 = random.randint(0,1000)
        ids.r2 = random.randint(0,1000)
        ids.r3 = random.randint(0,1000)
    %}

    with grid:
        let (position : Vector2) = grid_manip.generate_random_position_on_border(r1, r2, r3)
    end

    %{ assert ids.position.x == 0 or ids.position.x == 9 or ids.position.y == 0 or ids.position.y == 9 %}

    return ()
end
