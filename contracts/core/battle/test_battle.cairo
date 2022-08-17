%lang starknet

from contracts.core.battle.library import battle
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Dust
from contracts.models.common import Context, ShipInit, Vector2
from contracts.test.grid_helper import grid_helper

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

const RAND_CONTRACT = 11111

func assert_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    let (cell) = grid_access.get_cell_at(x, y)
    let (value) = cell_access.get_ship{cell=cell}()
    assert value = ship_id
    return ()
end

func assert_dust_count_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust_count : felt):
    let (cell) = grid_access.get_cell_at(x, y)
    let (value) = cell_access.get_dust_count{cell=cell}()
    assert value = dust_count
    return ()
end

func assert_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_cell_at(x, y)
    let (value) = cell_access.get_dust{cell=cell}()
    assert value = dust
    return ()
end

func add_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_cell_at(x, y)
    cell_access.add_dust{cell=cell}(dust)
    grid_access.set_cell_at(x, y, cell)
    return ()
end

func add_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
    alloc_locals

    let (cell) = grid_access.get_cell_at(x, y)
    local range_check_ptr = range_check_ptr  # revoked reference
    cell_access.add_ship{cell=cell}(ship_id)
    grid_access.set_cell_at(x, y, cell)

    let position = Vector2(x=x, y=y)
    grid_access.add_ship_position(position)

    return ()
end

func create_context_with_no_ship(ship_count : felt) -> (context : Context):
    const MAX_TURN_COUNT = 7
    const MAX_DUST_COUNT = 5
    return battle.create_context(RAND_CONTRACT, MAX_TURN_COUNT, MAX_DUST_COUNT, ship_count)
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
        battle.add_ships(context.ship_count, ships)
    end

    # Check context
    assert context.ship_contracts[0] = 'ship1'
    assert context.ship_contracts[1] = 'ship2'

    # Check grid content
    with grid:
        assert_ship_at(0, 0, 1)
        assert_ship_at(1, 1, 2)
    end

    # TODO ship_added.emit(battle_contract_address, ship_id, Vector2(position.x, position.y))

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
        %{ expect_revert(error_message='Battle: cell is not free') %}
        battle.add_ships(context.ship_count, ships)
    end

    return ()
end

@external
func test_spawn_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)
    with grid:
        add_ship_at(0, 0, 1)

        %{
            stop_mock = mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = 0
        let current_turn = 0
        with dust_count, current_turn, context:
            battle.spawn_dust()
        end
        %{ stop_mock() %}

        assert_dust_count_at(0, 5, 1)
        assert_dust_at(0, 5, Dust(Vector2(0, 1)))
        assert dust_count = 1

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

        %{
            stop_mock = mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                                   1, 2, # direction => (0, 1)
                                   0, 5, # position => (0, 5)
                                   0 # not shuffled
                                   ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = context.max_dust
        let current_turn = 0
        with dust_count, current_turn, context:
            battle.spawn_dust()
        end
        %{ stop_mock() %}

        assert_dust_count_at(0, 5, 0)
        assert dust_count = context.max_dust
    end

    return ()
end

@external
func test_spawn_no_dust_if_cell_occupied{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (grid) = grid_access.create(10)
    with grid:
        add_ship_at(0, 5, 1)

        %{
            stop_mock = mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                           1, 2, # direction => (0, 1)
                           0, 5, # position => (0, 5)
                           0 # not shuffled
                           ])
        %}
        let (context) = create_context_with_no_ship(1)
        local dust_count = 0
        let current_turn = 0
        with dust_count, current_turn, context:
            battle.spawn_dust()
        end
        %{ stop_mock() %}

        assert_dust_count_at(0, 5, 0)
        assert dust_count = 0
    end

    return ()
end

@external
func test_battle_dust_collision{syscall_ptr : felt*, range_check_ptr}():
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

        local dust_count = 4
        with dust_count:
            battle.burn_extra_dust()
        end

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust4)
            assert_dust_count_at(1, 1, 1)

            # TODO dust_destroyed.emit(contract_address, Vector2(x, y))
        end

        with_attr error_message("dust_count not updated"):
            assert dust_count = 1
        end
    end

    return ()
end

@external
func test_battle_ship_absorb_dust{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local syscall_ptr : felt* = syscall_ptr

    let dust = Dust(Vector2(1, 1))
    let ship = 1
    let (grid) = grid_access.create(3)
    let (context) = create_context_with_no_ship(2)
    let (scores) = battle.create_scores_array(2)

    with grid, context, scores:
        add_dust_at(1, 1, dust)
        add_ship_at(1, 1, ship)

        local dust_count = 1
        with dust_count:
            battle.check_ship_and_dust_collisions()
        end

        with_attr error_message("bad dust move"):
            assert_dust_count_at(1, 1, 0)
        end

        with_attr error_message("dust_count not updated"):
            assert dust_count = 0
        end
    end

    return ()
end

@external
func test_full_turn{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(1, 0))
    let dust2 = Dust(Vector2(-1, 0))
    let dust3 = Dust(Vector2(0, 1))
    let dust_spawned = Dust(Vector2(1, 1))

    let ship1 = 1
    let ship2 = 2

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = ship1
    assert ships[0].position = Vector2(1, 1)
    assert ships[1].address = ship2
    assert ships[1].position = Vector2(2, 3)

    let (grid) = grid_access.create(5)
    let (context) = create_context_with_no_ship(2)
    let (scores) = battle.create_scores_array(2)
    let dust_count = 3
    let current_turn = 3
    with grid, context, dust_count, current_turn, scores:
        # init
        battle.add_ships(context.ship_count, ships)
        add_dust_at(0, 0, dust1)
        add_dust_at(2, 0, dust2)
        add_dust_at(4, 1, dust3)

        %{
            mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                                                               2, 2, # direction => (1, 1)
                                                               0, 3, # position => (0, 3)
                                                               0 # not shuffled
                                                               ])

            mock_call(ids.ship1, "move", [0, -1])
            mock_call(ids.ship2, "move", [1, 0])
        %}

        grid_helper.debug_grid()
        battle.one_turn()
        grid_helper.debug_grid()

        with_attr error_message("Something wrong with ship1"):
            assert_ship_at(1, 0, ship1)
        end
        with_attr error_message("Something wrong with ship2"):
            assert_ship_at(3, 3, ship2)
        end
        with_attr error_message("Something wrong with dust3"):
            assert_dust_at(4, 2, dust3)
        end
        with_attr error_message("Something wrong with dust spawned"):
            assert_dust_at(0, 3, dust_spawned)
        end
        with_attr error_message("Something wrong with dust count"):
            assert dust_count = 2
        end
    end

    return ()
end

@external
func test_full_battle{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship1 = 1
    let ship2 = 2

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = ship1
    assert ships[0].position = Vector2(0, 9)
    assert ships[1].address = ship2
    assert ships[1].position = Vector2(4, 8)

    let (grid) = grid_access.create(10)
    let (context) = create_context_with_no_ship(2)
    let (scores) = battle.create_scores_array(2)

    with grid, context, scores:
        battle.add_ships(2, ships)
        let dust_count = 0
        let current_turn = 0
        with dust_count, current_turn:
            %{
                mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                                        2, 2, # direction => (1, 1)
                                        0, 2, # position => (0, 2)
                                           1 # shuffled position (0, 2) => (2, 0)
                                               ])

                mock_call(ids.ship1, "move", [1, -1])
                mock_call(ids.ship2, "move", [0, -1])
            %}
            battle.all_turns_loop()
        end
        # grid_helper.debug_grid()
        with_attr error_message("Something wrong with the battle"):
            assert_ship_at(6, 3, ship1)  # assert_ship_at(7, 2, ship1)  # assert_ship_at(6, 3, ship1)
            assert_ship_at(4, 1, ship2)
            assert_dust_count_at(3, 1, 1)
            assert_dust_count_at(4, 2, 1)
            assert_dust_count_at(5, 3, 0)  # This one was caught by ship2
            assert_dust_count_at(6, 4, 1)
            assert_dust_count_at(7, 5, 1)
            assert_dust_count_at(8, 6, 1)
        end

        # TODO game_finished.emit(battle_contract_address)
        # TODO new_turn.emit(battle_contract_address, current_turn + 1)
    end

    return ()
end

@external
func test_play_game{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let ship1 = 1
    let ship2 = 2

    let (local ships : ShipInit*) = alloc()
    assert ships[0].address = ship1
    assert ships[0].position = Vector2(0, 9)
    assert ships[1].address = ship2
    assert ships[1].position = Vector2(4, 8)

    %{
        mock_call(ids.RAND_CONTRACT, 'generate_random_numbers', [
                                                        2, 2, # direction => (1, 1)
                                                        0, 2, # position => (0, 2)
                                                        1 # shuffled position (0, 2) => (2, 0)
                                                        ])

        mock_call(ids.ship1, "move", [1, -1])
        mock_call(ids.ship2, "move", [0, -1])
    %}

    const SIZE = 10
    const TURN_COUNT = 7
    const MAX_DUST = 5

    let (scores_len : felt, scores : felt*) = battle.play_game(
        RAND_CONTRACT, SIZE, TURN_COUNT, MAX_DUST, 2, ships
    )

    # TODO score_changed.emit(battle_contract_address, ship_id, scores[ship_id] + 1)

    assert scores_len = 2
    assert scores[0] = 0  # ship1 caught no dust
    assert scores[1] = 1  # ship2 caught one dust

    return ()
end
