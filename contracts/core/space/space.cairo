# Declare this file as a StarkNet contract.
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.models.common import ShipInit, Grid, Vector2, Context, Dust
from contracts.interfaces.irand import IRandom
from contracts.libraries.grid import grid_manip
from contracts.core.library import MathUtils_random_direction

# ------------------
# EVENTS
# ------------------

@event
func ship_added(space_contract_address : felt, ship_id : felt, position : Vector2):
end

@event
func dust_spawned(space_contract_address : felt, direction : Vector2, position : Vector2):
end

# ------------------
# EXTERNAL FUNCTIONS
# ------------------

@external
func play_game{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(
    rand_contract_address : felt,
    size : felt,
    turn_count : felt,
    max_dust : felt,
    ships_len : felt,
    ships : ShipInit*,
):
    return ()  # Space.play_game(rand_contract_address, size, turn_count, max_dust, ships_len, ships)
end

namespace internal:
    func add_ship{syscall_ptr : felt*, range_check_ptr, grid : Grid, context : Context}(
        position : Vector2, ship_id : felt
    ):
        # Ensure the cell is free
        let (cell_is_occupied : felt) = grid_manip.is_cell_occupied(position.x, position.y)
        with_attr error_message("Space: cell is not free"):
            assert cell_is_occupied = 0
        end

        # Put the ship on the grid
        grid_manip.set_ship_at(position.x, position.y, ship_id)

        # Emit events
        let (space_contract_address) = get_contract_address()
        ship_added.emit(space_contract_address, ship_id, Vector2(position.x, position.y))

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

    func add_ships{syscall_ptr : felt*, range_check_ptr, grid : Grid, context : Context}(
        ships_len : felt, ships : ShipInit*
    ):
        if ships_len == 0:
            return ()
        end

        return add_ship_loop(ships_len, ships, 0)
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

        # Prevent spawning if cell is occupied
        let (cell_is_occupied) = grid_manip.is_cell_occupied(position.x, position.y)
        if cell_is_occupied == 1:
            return ()
        end

        # Finally, add dust to the grid
        grid_manip.set_dust_at(position.x, position.y, dust)
        let dust_count = dust_count + 1
        let (contract_address) = get_contract_address()
        dust_spawned.emit(contract_address, dust.direction, position)

        return ()
    end

    # Generate random dust given a space size
    func generate_random_dust_on_border{
        syscall_ptr : felt*, range_check_ptr, context : Context, grid : Grid, current_turn : felt
    }() -> (dust : Dust, position : Vector2):
        alloc_locals
        local dust : Dust
        assert dust.present = TRUE

        let (r1, r2, r3, r4, r5) = IRandom.generate_random_numbers(
            context.rand_contract, current_turn
        )

        let (direction : Vector2) = MathUtils_random_direction(r1, r2)
        assert dust.direction = direction

        let (position : Vector2) = grid_manip.generate_random_position_on_border(r3, r4, r5)

        return (dust=dust, position=position)
    end
end
