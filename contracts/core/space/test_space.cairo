%lang starknet

from contracts.core.space.space import internal as space
from contracts.libraries.grid import grid_manip
from contracts.models.common import Context, ShipInit, Dust

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

func create_context_with_no_ship(nb_ships : felt) -> (context : Context):
    alloc_locals

    local context : Context
    let (ship_addresses) = alloc()
    assert context.ship_contracts = ship_addresses
    assert context.nb_ships = nb_ships
    assert context.max_turn_count = 10
    assert context.max_dust = 10
    assert context.rand_contract = 11111

    return (context=context)
end

@external
func test_add_ships{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position.x = 0
    assert ships[0].position.y = 0
    assert ships[1].address = 'ship2'
    assert ships[1].position.x = 1
    assert ships[1].position.y = 1

    let (grid) = grid_manip.create(2)
    let (context) = create_context_with_no_ship(2)

    with grid, context:
        space.add_ships(context.nb_ships, ships)
    end

    # Check context
    assert context.ship_contracts[0] = 'ship1'
    assert context.ship_contracts[1] = 'ship2'

    # Check grid content
    with grid:
        with_attr error_message("Ship at position (0,0) is not 1"):
            let (ship) = grid_manip.get_ship_at(0, 0)
            assert ship = 1
        end

        with_attr error_message("Ship at position (1,1) is not 2"):
            let (ship) = grid_manip.get_ship_at(1, 1)
            assert ship = 2
        end
    end

    # TODO ship_added.emit(space_contract_address, ship_id, Vector2(position.x, position.y))

    return ()
end

@external
func test_add_ships_should_revert_if_cell_occupied{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position.x = 0
    assert ships[0].position.y = 0
    assert ships[1].address = 'ship2'
    assert ships[1].position.x = 0
    assert ships[1].position.y = 0

    let (grid) = grid_manip.create(2)
    let (context) = create_context_with_no_ship(2)

    with grid, context:
        %{ expect_revert(error_message='Space: cell is not free') %}
        space.add_ships(context.nb_ships, ships)
    end

    return ()
end

@external
func test_spawn_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_manip.create(10)
    let (context) = create_context_with_no_ship(1)

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position.x = 0
    assert ships[0].position.y = 0

    with grid, context:
        space.add_ships(context.nb_ships, ships)

        %{
            mock_call(ids.context.rand_contract, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let dust_count = 3
        let current_turn = 7
        with dust_count, current_turn:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}

        let (dust : Dust) = grid_manip.get_dust_at(0, 5)
        assert dust.present = TRUE
        assert dust.direction.x = 0
        assert dust.direction.y = 1
        assert dust_count = 4

        # TODO dust_spawned.emit(contract_address, dust.direction, position)
    end

    return ()
end

@external
func test_spawn_no_dust_if_max_dust_count_reached{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_manip.create(10)
    let (context) = create_context_with_no_ship(1)

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position.x = 0
    assert ships[0].position.y = 0

    with grid, context:
        space.add_ships(context.nb_ships, ships)

        %{
            mock_call(ids.context.rand_contract, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let dust_count = 10
        let current_turn = 7
        with dust_count, current_turn:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}

        let (dust : Dust) = grid_manip.get_dust_at(0, 5)
        assert dust.present = FALSE
        assert dust_count = 10
    end

    return ()
end

@external
func test_spawn_no_dust_if_cell_occupied{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_manip.create(10)
    let (context) = create_context_with_no_ship(1)

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = 'ship1'
    assert ships[0].position.x = 0
    assert ships[0].position.y = 5

    with grid, context:
        space.add_ships(context.nb_ships, ships)

        %{
            mock_call(ids.context.rand_contract, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let dust_count = 3
        let current_turn = 7
        with dust_count, current_turn:
            space.spawn_dust()
        end
        %{ clear_mock_call(ids.context.rand_contract, 'generate_random_numbers') %}

        let (dust : Dust) = grid_manip.get_dust_at(0, 5)
        assert dust.present = FALSE
        assert dust_count = 3
    end

    return ()
end
