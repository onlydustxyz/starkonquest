# Declare this file as a StarkNet contract.
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn, assert_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.bool import TRUE, FALSE

from contracts.models.common import Vector2, Dust, Cell, Context, Grid, ShipInit
from contracts.interfaces.iship import IShip
from contracts.interfaces.irand import IRandom
from contracts.core.library import (
    MathUtils_clamp_value,
    MathUtils_random_in_range,
    MathUtils_random_direction,
)
from contracts.libraries.grid import grid_manip

# ------
# EVENTS
# ------

@event
func dust_spawned(space_contract_address : felt, direction : Vector2, position : Vector2):
end

@event
func dust_destroyed(space_contract_address : felt, position : Vector2):
end

@event
func dust_moved(space_contract_address : felt, previous_position : Vector2, position : Vector2):
end

@event
func ship_moved(
    space_contract_address : felt, ship_id : felt, previous_position : Vector2, position : Vector2
):
end

@event
func score_changed(space_contract_address : felt, ship_id : felt, score : felt):
end

@event
func new_turn(space_contract_address : felt, turn_number : felt):
end

@event
func game_finished(space_contract_address : felt):
end

namespace Space:
    # ---------
    # EXTERNALS
    # ---------

    func play_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr,
    }(
        rand_contract_address : felt,
        size : felt,
        turn_count : felt,
        max_dust : felt,
        ships_len : felt,
        ships : ShipInit*,
    ):
        # alloc_locals

        # local context : Context

        # let ships_addresses : felt* = alloc()
        #     assert context.max_turn_count = turn_count
        #     assert context.max_dust = max_dust
        #     assert context.rand_contract = rand_contract_address
        #     assert context.ships_len = ships_len
        #     assert context.ships = ships_addresses

        # let dust_count = 0
        #     let scores : felt* = alloc()
        #     _init_scores_loop(scores, context.ships_len)

        # let (grid : Grid) = grid_manip.create(size)
        #     let (next_grid : Grid) = grid_manip.create(size)
        #     with context, grid, next_grid, dust_count, scores:
        #         _add_ships(ships_len, ships)
        #         _rec_play_turns(0)
        #     end

        return ()
    end

    # ---------
    # INTERNALS
    # ---------

    func _rec_play_turns{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
        scores : felt*,
    }(current_turn : felt):
        let (is_finished) = _next_turn(current_turn)
        if is_finished == TRUE:
            let (space_contract_address) = get_contract_address()
            game_finished.emit(space_contract_address)

            return ()
        end

        _rec_play_turns(current_turn + 1)
        return ()
    end

    # This function must be invoked to process the next turn of the game.
    func _next_turn{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
        scores : felt*,
    }(current_turn : felt) -> (is_finished : felt):
        alloc_locals

        let max_turn = context.max_turn_count

        let (local still_palying) = is_le(current_turn + 1, max_turn)
        if still_palying == 0:
            return (TRUE)
        end

        let (space_contract_address) = get_contract_address()
        new_turn.emit(space_contract_address, current_turn + 1)

        with current_turn:
            _spawn_dust()
        end

        _move_dust(0, 0)
        _move_ships(0, 0)
        _update_grid(0, 0)

        return (FALSE)
    end

    func _spawn_dust{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
        context : Context,
        grid : Grid,
        next_grid : Grid,
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
        let (local dust : Dust, position : Vector2) = _generate_random_dust_on_border()

        # Check there is no dust at this position yet
        let other_dust : Dust = grid_manip.get_dust_at{grid=next_grid}(position.x, position.y)
        if other_dust.present == TRUE:
            # There is already some dust here, so let's just skip dust spawning this turn
            return ()
        end

        # Finally, add dust to the grid

        grid_manip.set_dust_at{grid=next_grid}(position.x, position.y, dust)
        let dust_count = dust_count + 1
        let (contract_address) = get_contract_address()
        dust_spawned.emit(contract_address, dust.direction, position)

        return ()
    end

    # Recursive function that goes through the entire grid and updates dusts position
    func _move_dust{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
        scores : felt*,
    }(x : felt, y : felt):
        alloc_locals

        # We reached the last cell, this is the end
        if x == grid.size:
            return ()
        end
        # We reached the end of the column, let's go to the next one
        if y == grid.size:
            _move_dust(x + 1, 0)
            return ()
        end

        let (local dust : Dust) = grid_manip.get_dust_at(x, y)

        # if there is no dust here, we go directly to the next cell
        if dust.present == FALSE:
            _move_dust(x, y + 1)
            return ()
        end

        # There is some dust here! Let's move it
        let (local new_position : Vector2) = _compute_new_dust_position(dust, Vector2(x, y))

        # As the dust position changed, we free its old position
        grid_manip.clear_dust_at{grid=next_grid}(x, y)

        # Check collision with ship
        let (ship_id : felt) = grid_manip.get_ship_at(new_position.x, new_position.y)
        if ship_id != 0:
            # transfer dust to the ship and process next cell
            _catch_dust(dust, Vector2(new_position.x, new_position.y), ship_id)
            _move_dust(x, y + 1)
            return ()
        end

        # Check collision
        let (local other_dust : Dust) = grid_manip.get_dust_at{grid=next_grid}(
            new_position.x, new_position.y
        )

        if other_dust.present == TRUE:
            # In case of collision, do not assign the dust to the cell. The dust is lost forever.
            _burn_dust(dust, Vector2(x, y))

            # see https://www.cairo-lang.org/docs/how_cairo_works/builtins.html#revoked-implicit-arguments
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar context = context
            tempvar dust_count = dust_count
            tempvar grid = grid
            tempvar next_grid = next_grid
        else:
            # No collision. Update the dust position in the grid
            grid_manip.set_dust_at{grid=next_grid}(new_position.x, new_position.y, dust)

            let (space_contract_address) = get_contract_address()
            dust_moved.emit(space_contract_address, Vector2(x, y), new_position)

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar context = context
            tempvar dust_count = dust_count
            tempvar grid = grid
            tempvar next_grid = next_grid
        end

        # process the next cell
        _move_dust(x, y + 1)
        return ()
    end

    func _update_grid{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(x : felt, y : felt):
        alloc_locals

        # We reached the last cell, this is the end
        if x == grid.size:
            return ()
        end
        # We reached the end of the column, let's go to the next one
        if y == grid.size:
            _update_grid(x + 1, 0)
            return ()
        end

        let (local dust : Dust) = grid_manip.get_dust_at{grid=next_grid}(x, y)
        let (local ship_id : felt) = grid_manip.get_ship_at{grid=next_grid}(x, y)
        grid_manip.set_dust_at(x, y, dust)
        grid_manip.set_ship_at(x, y, ship_id)

        # process the next cell
        _update_grid(x, y + 1)
        return ()
    end

    # Recursive function that goes through the entire grid and updates ships position
    func _move_ships{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
        scores : felt*,
    }(x : felt, y : felt):
        alloc_locals

        # We reached the last cell, this is the end
        if x == grid.size:
            return ()
        end
        # We reached the end of the column, let's go to the next one
        if y == grid.size:
            _move_ships(x + 1, 0)
            return ()
        end

        let (local ship_id : felt) = grid_manip.get_ship_at(x, y)

        # if there is no ship here, we go directly to the next cell
        if ship_id == 0:
            _move_ships(x, y + 1)
            return ()
        end

        # Call ship contract
        let ship_contract = [context.ships + ship_id - 1]
        let (local new_direction : Vector2) = IShip.move(
            ship_contract, grid.nb_cells, grid.cells, ship_id
        )
        let (direction_x) = MathUtils_clamp_value(new_direction.x, -1, 1)
        let (direction_y) = MathUtils_clamp_value(new_direction.y, -1, 1)

        # Compute new position and check borders
        let (candidate_x) = MathUtils_clamp_value(x + direction_x, 0, grid.size - 1)
        let (candidate_y) = MathUtils_clamp_value(y + direction_y, 0, grid.size - 1)

        # Check collision with other ship
        let (local new_x, new_y) = _handle_collision_with_other_ship(x, y, candidate_x, candidate_y)

        let (space_contract_address) = get_contract_address()
        # TODO: When ship have unique ID, use this instead of `0`
        ship_moved.emit(space_contract_address, 0, Vector2(x, y), Vector2(new_x, new_y))

        # Check collision with dust
        let (dust : Dust) = grid_manip.get_dust_at(new_x, new_y)
        if dust.present == TRUE:
            # transfer dust to the ship
            _catch_dust(dust, Vector2(new_x, new_y), ship_id)

            # remove dust from the grid
            grid_manip.clear_dust_at(new_x, new_y)
            grid_manip.clear_dust_at{grid=next_grid}(new_x, new_y)

            # see https://www.cairo-lang.org/docs/how_cairo_works/builtins.html#revoked-implicit-arguments
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar context = context
            tempvar dust_count = dust_count
            tempvar scores = scores
            tempvar grid = grid
            tempvar next_grid = next_grid
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
            tempvar context = context
            tempvar dust_count = dust_count
            tempvar scores = scores
            tempvar grid = grid
            tempvar next_grid = next_grid
        end

        # Update the dust position in the grid
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar context = context
        tempvar dust_count = dust_count
        tempvar scores = scores
        tempvar grid = grid
        tempvar next_grid = next_grid
        grid_manip.clear_ship_at{grid=next_grid}(x, y)
        grid_manip.set_ship_at{grid=next_grid}(new_x, new_y, ship_id)

        # process the next cell
        _move_ships(x, y + 1)
        return ()
    end

    func _handle_collision_with_other_ship{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(old_x : felt, old_y : felt, new_x : felt, new_y : felt) -> (x : felt, y : felt):
        let (other_ship : felt) = grid_manip.get_ship_at{grid=next_grid}(new_x, new_y)
        if other_ship != 0:
            return (old_x, old_y)
        end
        return (new_x, new_y)
    end

    func _catch_dust{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
        scores : felt*,
    }(dust : Dust, position : Vector2, ship_id : felt):
        alloc_locals
        _burn_dust(dust, position)
        local dust_count = dust_count
        _increment_ship_score(ship_id)

        return ()
    end

    func _burn_dust{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        dust_count : felt,
    }(dust : Dust, position : Vector2):
        assert dust.present = TRUE

        assert_not_zero(dust_count)
        let dust_count = dust_count - 1

        let (contract_address) = get_contract_address()
        dust_destroyed.emit(contract_address, position)

        return ()
    end

    # Generate random dust given a space size
    func _generate_random_dust_on_border{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
        context : Context,
        grid : Grid,
        next_grid : Grid,
        current_turn : felt,
    }() -> (dust : Dust, position : Vector2):
        alloc_locals
        local dust : Dust
        assert dust.present = TRUE

        let (r1, r2, r3, r4, r5) = IRandom.generate_random_numbers(
            context.rand_contract, current_turn
        )

        let (direction : Vector2) = MathUtils_random_direction(r1, r2)
        assert dust.direction = direction

        let (position : Vector2) = _generate_random_position_on_border(r3, r4, r5)

        return (dust=dust, position=position)
    end

    # Generate a random position on a given border (top, left, right, bottom)
    func _generate_random_position_on_border{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(r1, r2, r3) -> (position : Vector2):
        alloc_locals

        # x is 0 or grid.size - 1
        let (x) = MathUtils_random_in_range(r1, 0, 1)
        local x = x * (grid.size - 1)

        # y is in [0, grid.size-1]
        let (y) = MathUtils_random_in_range(r2, 0, grid.size - 1)

        return _shuffled_position(x, y, r3)
    end

    # given x, y return randomly Position(x,y) or Position(y,x)
    func _shuffled_position{
        pedersen_ptr : HashBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(x : felt, y : felt, r) -> (position : Vector2):
        alloc_locals
        local position : Vector2

        let (on_horizontal_border) = MathUtils_random_in_range(r, 0, 1)
        if on_horizontal_border == 0:
            assert position.x = x
            assert position.y = y
        else:
            assert position.x = y
            assert position.y = x
        end

        return (position=position)
    end

    func _compute_new_dust_position{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(dust : Dust, current_position : Vector2) -> (new_position : Vector2):
        alloc_locals

        let (new_hdir) = _get_new_hdir(dust, current_position)
        let (new_vdir) = _get_new_vdir(dust, current_position)

        let new_x = current_position.x + new_hdir
        let new_y = current_position.y + new_vdir

        return (new_position=Vector2(x=new_x, y=new_y))
    end

    func _get_new_hdir{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(dust : Dust, current_position : Vector2) -> (hdir : felt):
        alloc_locals
        if current_position.x == grid.size - 1:
            if dust.direction.x == 1:
                return (hdir=-1)
            end
        end

        if current_position.x == 0:
            if dust.direction.x == -1:
                return (hdir=1)
            end
        end

        return (hdir=dust.direction.x)
    end

    func _get_new_vdir{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        grid : Grid,
        next_grid : Grid,
    }(dust : Dust, current_position : Vector2) -> (vdir : felt):
        alloc_locals
        if current_position.y == grid.size - 1:
            if dust.direction.y == 1:
                return (vdir=-1)
            end
        end

        if current_position.y == 0:
            if dust.direction.y == -1:
                return (vdir=1)
            end
        end

        return (vdir=dust.direction.y)
    end

    func _init_scores_loop(scores : felt*, size : felt):
        if size == 0:
            return ()
        end

        assert [scores] = 0
        return _init_scores_loop(scores + 1, size - 1)
    end

    func _increment_ship_score{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        scores : felt*,
    }(ship_id : felt):
        alloc_locals

        let (local new_scores : felt*) = alloc()
        _get_incremented_scores(context.ships_len, ship_id, new_scores)

        let scores = new_scores
        return ()
    end

    func _get_incremented_scores{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        context : Context,
        scores : felt*,
    }(ships_len : felt, ship_id : felt, new_scores : felt*):
        if ships_len == 0:
            return ()
        end

        if ship_id == context.ships_len - ships_len + 1:
            assert [new_scores] = [scores + ship_id - 1] + 1
        else:
            assert [new_scores] = [scores + ship_id - 1]
        end

        return _get_incremented_scores(ships_len - 1, ship_id, new_scores + 1)
    end
end
