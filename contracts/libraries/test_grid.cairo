%lang starknet

from contracts.libraries.grid import grid_manip
from contracts.models.common import Cell, Vector2, Dust, Grid

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_le

func assert_empty_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
    let (cell) = grid_manip.get_cell_at(x, y)
    assert cell.dust_count = 0
    assert cell.ship_id = 0
    return ()
end

func assert_dust_count_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust_count : felt):
    let (cell) = grid_manip.get_cell_at(x, y)
    assert cell.dust_count = dust_count
    return ()
end

func assert_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_manip.get_cell_at(x, y)
    assert cell.dust = dust
    return ()
end

func assert_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    let (cell) = grid_manip.get_cell_at(x, y)
    assert cell.ship_id = ship_id
    return ()
end

func assert_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, cell : Cell):
    let (cell) = grid_manip.get_cell_at(x, y)
    assert cell = cell
    return ()
end

func assert_cell_occupied_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
    let (is_cell_occupied) = grid_manip.is_cell_occupied(x, y)
    assert is_cell_occupied = 1
    return ()
end

func assert_cell_not_occupied_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
    let (is_cell_occupied) = grid_manip.is_cell_occupied(x, y)
    assert is_cell_occupied = 0
    return ()
end

@external
func test_grid_create_init_with_empty_cell{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    let empty_cell = Cell(0, Dust(Vector2(0, 0)), 0)
    let random_cell = Cell(3, Dust(Vector2(1, -1)), 42)

    assert grid.size = 2
    assert grid.nb_cells = 4

    with grid:
        assert_empty_cell_at(0, 0)
        assert_empty_cell_at(0, 1)
        assert_empty_cell_at(1, 0)
        assert_empty_cell_at(1, 1)
    end

    assert grid.cells[4] = random_cell  # Make sure the memory is free after the last cell

    return ()
end

@external
func test_grid_add_and_remove_dust{range_check_ptr}():
    let dust1 = Dust(Vector2(0, 1))
    let dust2 = Dust(Vector2(1, 0))
    let dust3 = Dust(Vector2(1, 1))

    let (grid) = grid_manip.create(2)

    with grid:
        grid_manip.add_dust_at(0, 1, dust1)
        grid_manip.add_dust_at(0, 1, dust2)
        grid_manip.add_dust_at(1, 1, dust3)

        with_attr error_message("dust not added"):
            assert_dust_count_at(0, 0, 0)
            assert_dust_count_at(0, 1, 2)
            assert_dust_at(0, 1, dust2)
            assert_dust_count_at(1, 0, 0)
            assert_dust_count_at(1, 1, 1)
            assert_dust_at(1, 1, dust3)
        end

        with_attr error_message("is_cell_occupied broken"):
            assert_cell_not_occupied_at(0, 0)
            assert_cell_occupied_at(0, 1)
            assert_cell_not_occupied_at(1, 0)
            assert_cell_occupied_at(1, 1)
        end

        grid_manip.remove_dust_at(0, 1)
        grid_manip.remove_dust_at(1, 1)

        with_attr error_message("dust not removed"):
            assert_dust_count_at(0, 0, 0)
            assert_dust_count_at(0, 1, 1)
            assert_dust_at(0, 1, dust2)
            assert_dust_count_at(1, 0, 0)
            assert_dust_count_at(1, 1, 0)
        end
    end

    return ()
end

@external
func test_grid_move_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(1, 1))  # top left, going down right
    let dust2 = Dust(Vector2(1, -1))  # top right, going down left
    let dust3 = Dust(Vector2(-1, -1))  # bottom right, going up left
    let dust4 = Dust(Vector2(-1, 1))  # bottom left, going up right

    let (grid) = grid_manip.create(4)

    with grid:
        grid_manip.add_dust_at(0, 0, dust1)
        grid_manip.add_dust_at(0, 3, dust2)
        grid_manip.add_dust_at(3, 3, dust3)
        grid_manip.add_dust_at(3, 0, dust4)

        grid_manip.move_all_dusts()
        local syscall_ptr : felt* = syscall_ptr  # TODO remove once event emitted out of grid_manip

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust1)
            assert_dust_at(1, 2, dust2)
            assert_dust_at(2, 2, dust3)
            assert_dust_at(2, 1, dust4)
        end
    end

    return ()
end

@external
func test_grid_move_dust_beyound_borders{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(-1, -1))  # top left, going up left
    let dust2 = Dust(Vector2(-1, 1))  # top right, going up right
    let dust3 = Dust(Vector2(1, 1))  # bottom right, going down right
    let dust4 = Dust(Vector2(1, -1))  # bottom left, going down left

    let new_dust1 = Dust(Vector2(1, 1))  # now going down right
    let new_dust2 = Dust(Vector2(1, -1))  # now going down left
    let new_dust3 = Dust(Vector2(-1, -1))  # now going up left
    let new_dust4 = Dust(Vector2(-1, 1))  # now going up right

    let (grid) = grid_manip.create(4)

    with grid:
        grid_manip.add_dust_at(0, 0, dust1)
        grid_manip.add_dust_at(0, 3, dust2)
        grid_manip.add_dust_at(3, 3, dust3)
        grid_manip.add_dust_at(3, 0, dust4)

        grid_manip.move_all_dusts()
        local syscall_ptr : felt* = syscall_ptr  # TODO remove once event emitted out of grid_manip

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, new_dust1)
            assert_dust_at(1, 2, new_dust2)
            assert_dust_at(2, 2, new_dust3)
            assert_dust_at(2, 1, new_dust4)
        end
    end

    return ()
end

@external
func test_grid_move_dust_and_burn{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(1, 1))  # top left, going down right
    let dust2 = Dust(Vector2(1, -1))  # top right, going down left
    let dust3 = Dust(Vector2(-1, -1))  # bottom right, going up left
    let dust4 = Dust(Vector2(-1, 1))  # bottom left, going up right

    let (grid) = grid_manip.create(3)

    with grid:
        grid_manip.add_dust_at(0, 0, dust1)
        grid_manip.add_dust_at(0, 2, dust2)
        grid_manip.add_dust_at(2, 2, dust3)
        grid_manip.add_dust_at(2, 0, dust4)

        grid_manip.move_all_dusts()
        local syscall_ptr : felt* = syscall_ptr  # TODO remove once event emitted out of grid_manip

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust3)
            assert_dust_count_at(1, 1, 1)

            # TODO dust_destroyed.emit(contract_address, Vector2(x, y))
        end
    end

    return ()
end

@external
func test_grid_set_and_remove_ship{range_check_ptr}():
    let no_ship = 0
    let ship1 = 11
    let ship2 = 22

    let (grid) = grid_manip.create(2)
    with grid:
        grid_manip.set_ship_at(0, 1, ship1)
        grid_manip.set_ship_at(1, 1, ship2)

        with_attr error_message("dust not added"):
            assert_ship_at(0, 0, no_ship)
            assert_ship_at(0, 1, ship1)
            assert_ship_at(1, 0, no_ship)
            assert_ship_at(1, 1, ship2)
        end

        with_attr error_message("is_cell_occupied broken"):
            assert_cell_not_occupied_at(0, 0)
            assert_cell_occupied_at(0, 1)
            assert_cell_not_occupied_at(1, 0)
            assert_cell_occupied_at(1, 1)
        end

        grid_manip.remove_ship_at(1, 1)

        with_attr error_message("dust not removed"):
            assert_ship_at(0, 0, no_ship)
            assert_ship_at(0, 1, ship1)
            assert_ship_at(1, 0, no_ship)
            assert_ship_at(1, 1, no_ship)
        end
    end

    return ()
end

@external
func test_grid_set_clear_should_preserve_other_objects{range_check_ptr}():
    let dust1 = Dust(Vector2(1, 1))
    let dust2 = Dust(Vector2(-1, -1))

    let no_ship = 0
    let ship1 = 11
    let ship2 = 22

    let (grid) = grid_manip.create(2)
    with grid:
        grid_manip.add_dust_at(0, 0, dust1)
        grid_manip.set_ship_at(0, 0, ship1)

        grid_manip.add_dust_at(1, 1, dust2)
        grid_manip.set_ship_at(1, 1, ship2)

        with_attr error_message("grid not updated correctly"):
            assert_cell_at(0, 0, Cell(1, dust1, ship1))
            assert_cell_at(1, 1, Cell(1, dust1, ship1))
        end

        with_attr error_message("is_cell_occupied broken"):
            assert_cell_occupied_at(0, 0)
            assert_cell_not_occupied_at(0, 1)
            assert_cell_not_occupied_at(1, 0)
            assert_cell_occupied_at(1, 1)
        end

        grid_manip.remove_ship_at(0, 0)
        grid_manip.remove_dust_at(1, 1)

        with_attr error_message("clear_ship/dust removed other objects"):
            assert_cell_at(0, 0, Cell(1, dust1, no_ship))
            assert_cell_at(1, 1, Cell(0, dust1, ship2))
        end
    end

    return ()
end

@external
func test_grid_set_dust_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.add_dust_at(0, 3, Dust(Vector2(1, 1)))
    end

    return ()
end

@external
func test_grid_get_cell_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.get_cell_at(0, 3)
    end

    return ()
end

@external
func test_grid_remove_dust_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.remove_dust_at(0, 3)
    end

    return ()
end

@external
func test_grid_remove_dust_should_revert_if_no_dust{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="No dust to remove here") %}
        grid_manip.remove_dust_at(0, 0)
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
func test_grid_remove_ship_should_revert_if_out_of_bound{range_check_ptr}():
    let (grid) = grid_manip.create(2)
    with grid:
        %{ expect_revert(error_message="Out of bound") %}
        grid_manip.remove_ship_at(0, 3)
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
