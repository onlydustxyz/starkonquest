%lang starknet

from contracts.libraries.move import move_strategy
from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Dust
from contracts.test.grid_helper import grid_helper
from starkware.cairo.common.alloc import alloc

func add_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = cell_access.create()
    cell_access.add_dust{cell=cell}(dust)
    grid_access.set_cell_at(x, y, cell)
    return ()
end

func assert_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_cell_at(x, y)
    assert cell.dust = dust
    return ()
end

func add_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    let (cell) = cell_access.create()
    cell_access.add_ship{cell=cell}(ship_id)
    grid_access.set_cell_at(x, y, cell)
    return ()
end

func assert_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    let (cell) = grid_access.get_cell_at(x, y)
    assert cell.ship_id = ship_id
    return ()
end

@external
func test_move_dusts{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(1, 1))  # top left, going down right
    let dust2 = Dust(Vector2(1, -1))  # top right, going down left
    let dust3 = Dust(Vector2(-1, -1))  # bottom right, going up left
    let dust4 = Dust(Vector2(-1, 1))  # bottom left, going up right

    let (grid) = grid_access.create(4)
    with grid:
        add_dust_at(0, 0, dust1)
        add_dust_at(0, 3, dust2)
        add_dust_at(3, 3, dust3)
        add_dust_at(3, 0, dust4)
        # grid_access.apply_modifications()
        grid_helper.debug_grid()

        move_strategy.move_all_dusts()
        # grid_access.apply_modifications()
        grid_helper.debug_grid()
        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust1)
            assert_dust_at(1, 2, dust2)
            assert_dust_at(2, 2, dust3)
            assert_dust_at(2, 1, dust4)
            # TODO dust_moved.emit(space_contract_address, grid_iterator, new_dust_position)
        end
    end

    return ()
end

@external
func test_grid_move_dust_beyond_borders{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(-1, -1))  # top left, going up left
    let dust2 = Dust(Vector2(-1, 1))  # top right, going up right
    let dust3 = Dust(Vector2(1, 1))  # bottom right, going down right
    let dust4 = Dust(Vector2(1, -1))  # bottom left, going down left

    let new_dust1 = Dust(Vector2(1, 1))  # now going down right
    let new_dust2 = Dust(Vector2(1, -1))  # now going down left
    let new_dust3 = Dust(Vector2(-1, -1))  # now going up left
    let new_dust4 = Dust(Vector2(-1, 1))  # now going up right

    let (grid) = grid_access.create(4)
    with grid:
        add_dust_at(0, 0, dust1)
        add_dust_at(0, 3, dust2)
        add_dust_at(3, 3, dust3)
        add_dust_at(3, 0, dust4)
        # grid_access.apply_modifications()

        move_strategy.move_all_dusts()
        # grid_access.apply_modifications()

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, new_dust1)
            assert_dust_at(1, 2, new_dust2)
            assert_dust_at(2, 2, new_dust3)
            assert_dust_at(2, 1, new_dust4)
            # TODO dust_moved.emit(space_contract_address, grid_iterator, new_dust_position)
        end
    end

    return ()
end

@external
func test_move_ship_nominal{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship = 1
    let ship_contract = 'ship'
    let (local ship_addresses) = alloc()
    assert ship_addresses[0] = ship_contract

    let (grid) = grid_access.create(4)
    with grid:
        add_ship_at(0, 0, ship)
        # grid_access.apply_modifications()

        %{ stop_mock = mock_call(ids.ship_contract, "move", [1, 1]) %}
        move_strategy.move_all_ships(ship_addresses)
        %{ stop_mock() %}
        # grid_access.apply_modifications()

        with_attr error_message("bad ship move"):
            assert_ship_at(1, 1, ship)
            # TODO ship_moved.emit(space_contract_address, ship_id, grid_iterator, new_position)
        end
    end

    return ()
end

@external
func test_move_ship_collision_in_current_grid{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship1 = 1
    let ship2 = 2
    let ship1_contract = 'ship1'
    let ship2_contract = 'ship2'

    let (local ship_addresses) = alloc()
    assert ship_addresses[0] = ship1_contract
    assert ship_addresses[1] = ship2_contract

    let (grid) = grid_access.create(3)
    with grid:
        add_ship_at(0, 0, ship1)
        add_ship_at(0, 1, ship2)
        # grid_access.apply_modifications()

        %{
            stop_mocks_1 = mock_call(ids.ship1_contract, "move", [0, 1])
            stop_mocks_2 = mock_call(ids.ship2_contract, "move", [0, 1])
        %}
        move_strategy.move_all_ships(ship_addresses)
        %{
            stop_mocks_1()
            stop_mocks_2()
        %}
        # grid_access.apply_modifications()

        with_attr error_message("bad ship move"):
            assert_ship_at(0, 0, ship1)
            assert_ship_at(0, 2, ship2)
            # TODO ship_moved.emit(space_contract_address, ship_id, grid_iterator, new_position)
        end
    end

    return ()
end

@external
func test_move_ship_collision_in_next_grid{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship1 = 1
    let ship2 = 2
    let ship1_contract = 'ship1'
    let ship2_contract = 'ship2'

    let (local ship_addresses) = alloc()
    assert ship_addresses[0] = ship1_contract
    assert ship_addresses[1] = ship2_contract

    let (grid) = grid_access.create(4)
    with grid:
        add_ship_at(0, 1, ship1)
        add_ship_at(1, 0, ship2)
        # grid_access.apply_modifications()
        grid_helper.debug_grid()

        %{
            stop_mock_1 = mock_call(ids.ship1_contract, "move", [1, 0])
            stop_mock_2 = mock_call(ids.ship2_contract, "move", [0, 1])
        %}
        move_strategy.move_all_ships(ship_addresses)
        grid_helper.debug_grid()

        %{
            stop_mock_1()
            stop_mock_2()
        %}
        # grid_access.apply_modifications()

        with_attr error_message("bad ship move"):
            assert_ship_at(0, 1, ship1)
            assert_ship_at(1, 1, ship2)
            # TODO ship_moved.emit(space_contract_address, ship_id, grid_iterator, new_position)
        end
    end

    return ()
end

@external
func test_move_ship_should_revert_if_out_of_bound{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship = 1
    let ship_contract = 'ship'
    let (local ship_addresses) = alloc()
    assert ship_addresses[0] = ship_contract

    let (grid) = grid_access.create(4)
    with grid:
        add_ship_at(0, 0, ship)
        # grid_access.apply_modifications()

        %{
            stop_mock = mock_call(ids.ship_contract, "move", [-1, 1])
            expect_revert(error_message="Out of bound")
        %}
        move_strategy.move_all_ships(ship_addresses)
    end
    %{ stop_mock() %}

    return ()
end
