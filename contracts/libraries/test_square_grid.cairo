%lang starknet

from contracts.libraries.square_grid import Grid, grid_access
from contracts.libraries.cell import Cell, cell_access
from contracts.models.common import Vector2

func assert_current_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, cell : Cell):
    let (current_cell) = grid_access.get_current_cell_at(x, y)
    assert current_cell = cell
    return ()
end

func assert_next_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, cell : Cell):
    let (next_cell) = grid_access.get_next_cell_at(x, y)
    assert next_cell = cell
    return ()
end

@external
func test_grid_create{range_check_ptr}():
    alloc_locals

    let (local grid) = grid_access.create(2)
    let (empty_cell) = cell_access.create()

    let (random_cell) = cell_access.create()
    cell_access.add_ship{cell=random_cell}(23)

    assert grid.width = 2
    assert grid.nb_cells = 4

    with grid:
        assert_current_cell_at(0, 0, empty_cell)
        assert_current_cell_at(0, 1, empty_cell)
        assert_current_cell_at(1, 0, empty_cell)
        assert_current_cell_at(1, 1, empty_cell)

        assert_next_cell_at(0, 0, empty_cell)
        assert_next_cell_at(0, 1, empty_cell)
        assert_next_cell_at(1, 0, empty_cell)
        assert_next_cell_at(1, 1, empty_cell)
    end

    assert grid.current_cells[4] = random_cell  # Make sure the memory is free after the last cell
    assert grid.next_cells[4] = random_cell  # Make sure the memory is free after the last cell

    return ()
end

@external
func test_grid_update{range_check_ptr}():
    alloc_locals

    let (local grid) = grid_access.create(2)

    with grid:
        let (empty_cell) = cell_access.create()
        let (cell_with_ship) = cell_access.create()
        cell_access.add_ship{cell=cell_with_ship}(23)

        grid_access.set_next_cell_at(0, 1, cell_with_ship)

        assert_current_cell_at(0, 1, empty_cell)
        assert_next_cell_at(0, 1, cell_with_ship)

        grid_access.apply_modifications()

        assert_current_cell_at(0, 1, cell_with_ship)
        assert_next_cell_at(0, 1, empty_cell)
    end

    return ()
end

@external
func test_grid_set_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    let (cell) = cell_access.create()
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.set_next_cell_at(0, 3, cell)
    end

    return ()
end

@external
func test_grid_get_current_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.get_current_cell_at(0, 3)
    end

    return ()
end

@external
func test_grid_get_next_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_access.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_access.get_next_cell_at(0, 3)
    end

    return ()
end

@external
func test_generate_random_position_on_border{range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)

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
        let (position : Vector2) = grid_access.generate_random_position_on_border(r1, r2, r3)
    end

    %{ assert ids.position.x == 0 or ids.position.x == 9 or ids.position.y == 0 or ids.position.y == 9 %}

    return ()
end
