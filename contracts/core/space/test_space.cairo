%lang starknet

from contracts.core.space.space import internal as space
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Dust
from contracts.models.common import Context, ShipInit, Vector2

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

const RAND_CONTRACT = 11111

func assert_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    let (cell) = grid_access.get_current_cell_at(x, y)
    let (value) = cell_access.get_ship{cell=cell}()
    assert value = ship_id
    return ()
end

func assert_dust_count_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust_count : felt):
    let (cell) = grid_access.get_current_cell_at(x, y)
    let (value) = cell_access.get_dust_count{cell=cell}()
    assert value = dust_count
    return ()
end

func assert_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_current_cell_at(x, y)
    let (value) = cell_access.get_dust{cell=cell}()
    assert value = dust
    return ()
end

func add_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_current_cell_at(x, y)
    cell_access.add_dust{cell=cell}(dust)
    grid_access.set_next_cell_at(x, y, cell)
    return ()
end

func add_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    alloc_locals

    let (cell) = grid_access.get_current_cell_at(x, y)
    local range_check_ptr = range_check_ptr  # rvoked reference
    cell_access.add_ship{cell=cell}(ship_id)
    grid_access.set_next_cell_at(x, y, cell)
    return ()
end

func create_context_with_no_ship(ship_count : felt) -> (context : Context):
    alloc_locals

    local context : Context
    let (ship_addresses) = alloc()
    assert context.ship_contracts = ship_addresses
    assert context.ship_count = ship_count
    assert context.max_turn_count = 10
    assert context.max_dust = 10
    assert context.rand_contract = RAND_CONTRACT

    return (context=context)
end

@external
func test_add_ships{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position = Vector2(0, 0)
    assert ships[1].address = 'ship2'
    assert ships[1].position = Vector2(1, 1)

    let (grid) = grid_access.create(2)
    let (context) = create_context_with_no_ship(2)

    with grid, context:
        space.add_ships(context.ship_count, ships)
        grid_access.apply_modifications()
    end

    # Check context
    assert context.ship_contracts[0] = 'ship1'
    assert context.ship_contracts[1] = 'ship2'

    # Check grid content
    with grid:
        assert_ship_at(0, 0, 1)
        assert_ship_at(1, 1, 2)
    end

    # TODO ship_added.emit(space_contract_address, ship_id, Vector2(position.x, position.y))

    return ()
end

@external
func test_add_ships_should_revert_if_cell_occupied{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position = Vector2(0, 0)
    assert ships[1].address = 'ship2'
    assert ships[1].position = Vector2(0, 0)

    let (grid) = grid_access.create(2)
    let (context) = create_context_with_no_ship(2)

    with grid, context:
        %{ expect_revert(error_message='Space: cell is not free') %}
        space.add_ships(context.ship_count, ships)
    end

    return ()
end

@external
func test_spawn_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)
    with grid:
        add_ship_at(0, 0, 1)
        grid_access.apply_modifications()

        %{
            mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = 3
        let current_turn = 7
        with dust_count, current_turn, context:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}

        grid_access.apply_modifications()

        assert_dust_count_at(0, 5, 1)
        assert_dust_at(0, 5, Dust(Vector2(0, 1)))
        assert dust_count = 4

        # TODO dust_spawned.emit(contract_address, dust.direction, position)
    end

    return ()
end

@external
func test_spawn_no_dust_if_max_dust_count_reached{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)
    with grid:
        add_ship_at(0, 0, 1)
        grid_access.apply_modifications()

        %{
            mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = 10
        let current_turn = 7
        with dust_count, current_turn, context:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}

        grid_access.apply_modifications()

        assert_dust_count_at(0, 5, 0)
        assert dust_count = 10
    end

    return ()
end

@external
func test_spawn_no_dust_if_cell_occupied{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)
    with grid:
        add_ship_at(0, 5, 1)
        grid_access.apply_modifications()

        %{
            mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = 3
        let current_turn = 7
        with dust_count, current_turn, context:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}
        grid_access.apply_modifications()

        assert_dust_count_at(0, 5, 0)
        assert dust_count = 3
    end

    return ()
end

@external
func test_space_dust_collision{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local syscall_ptr : felt* = syscall_ptr

    let dust1 = Dust(Vector2(1, 1))
    let dust2 = Dust(Vector2(1, -1))
    let dust3 = Dust(Vector2(-1, -1))
    let dust4 = Dust(Vector2(-1, 1))

    let (grid) = grid_access.create(3)

    with grid:
        add_dust_at(1, 1, dust1)
        add_dust_at(1, 1, dust2)
        add_dust_at(1, 1, dust3)
        add_dust_at(1, 1, dust4)

        space.burn_extra_dust()
        grid_access.apply_modifications()

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust4)
            assert_dust_count_at(1, 1, 1)

            # TODO dust_destroyed.emit(contract_address, Vector2(x, y))
        end
    end

    return ()
end

@external
func test_space_ship_absorb_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local syscall_ptr : felt* = syscall_ptr

    let dust = Dust(Vector2(1, 1))
    let ship = 1
    let (grid) = grid_access.create(3)

    with grid:
        add_dust_at(1, 1, dust)
        add_ship_at(1, 1, ship)

        space.check_ship_and_dust_collisions()
        grid_access.apply_modifications()

        with_attr error_message("bad dust move"):
            assert_dust_count_at(1, 1, 0)
        end
    end

    return ()
end
