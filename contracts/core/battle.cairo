# Declare this file as a StarkNet contract.
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_nn_le

from contracts.models.common import ShipInit, Vector2, Context
from contracts.interfaces.irand import IRandom
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust
from contracts.libraries.move import move_strategy
from contracts.core.library import MathUtils_random_direction

# ------------------
# EVENTS
# ------------------

@event
func ship_added(battle_contract_address : felt, ship_id : felt, position : Vector2):
end

@event
func dust_spawned(battle_contract_address : felt, direction : Vector2, position : Vector2):
end

@event
func dust_destroyed(battle_contract_address : felt, position : Vector2):
end

@event
func new_turn(battle_contract_address : felt, turn_number : felt):
end

@event
func game_finished(battle_contract_address : felt):
end

@event
func score_changed(battle_contract_address : felt, ship_id : felt, score : felt):
end

# ------------------
# EXTERNAL FUNCTIONS
# ------------------

@external
func play_game{syscall_ptr : felt*, range_check_ptr}(
    rand_contract_address : felt,
    size : felt,
    turn_count : felt,
    max_dust : felt,
    ships_len : felt,
    ships : ShipInit*,
) -> (scores_len : felt, scores : felt*):
    return internal.play_game(rand_contract_address, size, turn_count, max_dust, ships_len, ships)
end

namespace internal:
    func play_game{syscall_ptr : felt*, range_check_ptr}(
        rand_contract_address : felt,
        size : felt,
        turn_count : felt,
        max_dust : felt,
        ships_len : felt,
        ships : ShipInit*,
    ) -> (scores_len : felt, scores : felt*):
        alloc_locals

        let (local grid) = grid_access.create(size)
        let (scores) = create_scores_array(ships_len)
        let (context) = internal.create_context(
            rand_contract_address, turn_count, max_dust, ships_len
        )

        with grid, context, scores:
            internal.add_ships(ships_len, ships)
            grid_access.apply_modifications()

            let dust_count = 0
            let current_turn = 0
            with dust_count, current_turn:
                internal.all_turns_loop()
            end
        end

        let (battle_contract_address) = get_contract_address()
        game_finished.emit(battle_contract_address)

        return (scores_len=ships_len, scores=scores)
    end

    func create_scores_array(scores_len : felt) -> (scores : felt*):
        alloc_locals

        let (new_array) = alloc()
        local scores : felt* = new_array
        init_scores_loop(scores_len, scores)

        return (scores=scores)
    end

    func init_scores_loop(scores_len : felt, scores : felt*):
        if scores_len == 0:
            return ()
        end

        assert [scores] = 0
        return init_scores_loop(scores_len - 1, scores + 1)
    end

    func create_context(
        rand_contract_address : felt, turn_count : felt, max_dust : felt, ships_len : felt
    ) -> (context : Context):
        alloc_locals

        local context : Context
        let (ship_addresses) = alloc()
        assert context.ship_contracts = ship_addresses
        assert context.ship_count = ships_len
        assert context.max_turn_count = turn_count
        assert context.max_dust = max_dust
        assert context.rand_contract = rand_contract_address

        return (context=context)
    end

    func all_turns_loop{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        context : Context,
        dust_count : felt,
        current_turn : felt,
        scores : felt*,
    }():
        if current_turn == context.max_turn_count:
            return ()  # end of the battle
        end

        let (battle_contract_address) = get_contract_address()
        new_turn.emit(battle_contract_address, current_turn + 1)

        one_turn()
        let current_turn = current_turn + 1

        return all_turns_loop()
    end

    func one_turn{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        context : Context,
        dust_count,
        current_turn,
        scores : felt*,
    }():
        alloc_locals

        local syscall_ptr : felt* = syscall_ptr
        move_strategy.move_all_ships(context.ship_contracts)
        move_strategy.move_all_dusts()
        burn_extra_dust()
        check_ship_and_dust_collisions()
        spawn_dust()
        grid_access.apply_modifications()

        return ()
    end

    func add_ships{syscall_ptr : felt*, range_check_ptr, grid : Grid, context : Context}(
        ships_len : felt, ships : ShipInit*
    ):
        alloc_locals

        if ships_len == 0:
            return ()
        end

        add_ship_loop(ships_len, ships, 0)
        local context : Context = context  # reference revoked

        return ()
    end

    func add_ship_loop{syscall_ptr : felt*, range_check_ptr, grid : Grid, context : Context}(
        ships_len : felt, ships : ShipInit*, ship_index : felt
    ):
        if ship_index == ships_len:
            return ()
        end

        let ship : ShipInit = ships[ship_index]
        add_ship(ship.position, ship_index + 1)
        assert context.ship_contracts[ship_index] = ship.address

        return add_ship_loop(ships_len, ships, ship_index + 1)
    end

    func add_ship{syscall_ptr : felt*, range_check_ptr, grid : Grid}(
        position : Vector2, ship_id : felt
    ):
        alloc_locals

        let (cell) = grid_access.get_next_cell_at(position.x, position.y)
        local range_check_ptr = range_check_ptr  # revoked reference
        with cell:
            # Ensure the cell is free
            let (cell_is_occupied : felt) = cell_access.is_occupied()
            with_attr error_message("Battle: cell is not free"):
                assert cell_is_occupied = 0
            end

            # Put the ship on the grid
            cell_access.add_ship(ship_id)
            grid_access.set_next_cell_at(position.x, position.y, cell)
        end

        # Emit events
        let (battle_contract_address) = get_contract_address()
        ship_added.emit(battle_contract_address, ship_id, Vector2(position.x, position.y))

        return ()
    end

    func spawn_dust{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        context : Context,
        dust_count : felt,
        current_turn : felt,
    }():
        alloc_locals
        let max_dust = context.max_dust

        # Check if we already reached the max amount of dust in the grid
        if dust_count == max_dust:
            return ()
        end

        # Create a new Dust at random position on a border and with random direction
        let (local dust : Dust, position : Vector2) = internal.generate_random_dust_on_border()

        # Prevent spawning if next cell is occupied
        let (cell) = grid_access.get_next_cell_at(position.x, position.y)
        with cell:
            let (cell_is_occupied) = cell_access.is_occupied()
            if cell_is_occupied == 1:
                return ()
            end

            # Finally, add dust to the grid
            cell_access.add_dust(dust)
        end
        grid_access.set_next_cell_at(position.x, position.y, cell)
        let dust_count = dust_count + 1

        let (contract_address) = get_contract_address()
        dust_spawned.emit(contract_address, dust.direction, position)

        return ()
    end

    func burn_extra_dust{syscall_ptr : felt*, range_check_ptr, grid : Grid, dust_count}():
        let (grid_iterator) = grid_access.start()
        with grid_iterator:
            burn_extra_dust_loop()
        end
        return ()
    end

    func burn_extra_dust_loop{
        syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2, dust_count
    }():
        let (done) = grid_access.done()
        if done == 1:
            return ()
        end

        let (dust_burnt) = try_burn_extra_dust()
        let dust_count = dust_count - dust_burnt
        if dust_burnt == 0:
            # Do not go to next cell if dust was burnt, there might be other dust to burn
            grid_access.next()
            return burn_extra_dust_loop()
        end

        return burn_extra_dust_loop()
    end

    func try_burn_extra_dust{
        syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
    }() -> (dust_burnt : felt):
        alloc_locals

        let (cell) = grid_access.get_next_cell_at(grid_iterator.x, grid_iterator.y)
        local grid : Grid = grid  # revoked reference
        with cell:
            let (dust_count) = cell_access.get_dust_count{cell=cell}()
            let (extra_dust) = is_nn_le(2, dust_count)
            if extra_dust == 0:
                return (dust_burnt=0)
            end

            cell_access.remove_dust()
        end

        grid_access.set_next_cell_at(grid_iterator.x, grid_iterator.y, cell)

        let (contract_address) = get_contract_address()
        dust_destroyed.emit(contract_address, grid_iterator)

        return (dust_burnt=1)
    end

    func check_ship_and_dust_collisions{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        dust_count,
        context : Context,
        scores : felt*,
    }():
        let (grid_iterator) = grid_access.start()
        with grid_iterator:
            check_ship_and_dust_collisions_loop()
        end
        return ()
    end

    func check_ship_and_dust_collisions_loop{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        grid_iterator : Vector2,
        dust_count,
        context : Context,
        scores : felt*,
    }():
        let (done) = grid_access.done()
        if done == 1:
            return ()
        end

        let (dust_absorbed) = try_ship_absorb_dust()
        let dust_count = dust_count - dust_absorbed

        grid_access.next()
        return check_ship_and_dust_collisions_loop()
    end

    func try_ship_absorb_dust{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        grid_iterator : Vector2,
        context : Context,
        scores : felt*,
    }() -> (dust_absorbed : felt):
        alloc_locals

        let (cell) = grid_access.get_next_cell_at(grid_iterator.x, grid_iterator.y)
        local grid : Grid = grid  # revoked reference
        with cell:
            let (has_ship) = cell_access.has_ship()
            let (has_dust) = cell_access.has_dust()
            if has_dust * has_ship == 0:
                return (dust_absorbed=0)
            end

            cell_access.remove_dust()
            grid_access.set_next_cell_at(grid_iterator.x, grid_iterator.y, cell)
            increment_ship_score()
        end

        return (dust_absorbed=1)
    end

    func increment_ship_score{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        grid_iterator : Vector2,
        context : Context,
        scores : felt*,
    }():
        alloc_locals

        let (cell) = grid_access.get_next_cell_at(grid_iterator.x, grid_iterator.y)
        let (ship_id) = cell_access.get_ship{cell=cell}()

        let (new_array) = alloc()
        local new_scores : felt* = new_array
        let ship_index = ship_id - 1
        let new_ship_score = scores[ship_index] + 1
        update_scores_loop(new_scores, 0, ship_index, new_ship_score)

        let (battle_contract_address) = get_contract_address()
        score_changed.emit(battle_contract_address, ship_id, new_ship_score)

        let scores = new_scores
        return ()
    end

    func update_scores_loop{
        syscall_ptr : felt*,
        range_check_ptr,
        grid : Grid,
        grid_iterator : Vector2,
        context : Context,
        scores : felt*,
    }(new_scores : felt*, index : felt, ship_index : felt, new_ship_score : felt):
        if index == context.ship_count:
            return ()
        end

        if index == ship_index:
            assert new_scores[index] = new_ship_score
        else:
            assert new_scores[index] = scores[index]
        end

        return update_scores_loop(new_scores, index + 1, ship_index, new_ship_score)
    end

    # Generate random dust given a battle size
    func generate_random_dust_on_border{
        syscall_ptr : felt*, range_check_ptr, context : Context, grid : Grid, current_turn : felt
    }() -> (dust : Dust, position : Vector2):
        alloc_locals
        local dust : Dust

        let (r1, r2, r3, r4, r5) = IRandom.generate_random_numbers(
            context.rand_contract, current_turn
        )

        let (direction : Vector2) = MathUtils_random_direction(r1, r2)
        assert dust.direction = direction

        let (position : Vector2) = grid_access.generate_random_position_on_border(r3, r4, r5)

        return (dust=dust, position=position)
    end
end
