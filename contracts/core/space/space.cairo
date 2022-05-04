# Declare this file as a StarkNet contract.
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.models.common import ShipInit, Grid, Vector2, Context
from contracts.core.space.library import Space
from contracts.libraries.grid import grid_manip

# ------------------
# EVENTS
# ------------------

@event
func ship_added(space_contract_address : felt, ship_id : felt, position : Vector2):
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
    return Space.play_game(rand_contract_address, size, turn_count, max_dust, ships_len, ships)
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
        assert context.ships[ship_index] = ship.address

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
end
