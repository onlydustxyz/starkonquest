%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.models.common import Vector2
from contracts.libraries.cell import Cell
from contracts.ships.basic_ship.library import BasicShip

@external
func move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    grid_len : felt, grid : Cell*, self : felt
) -> (new_direction : Vector2):
    with grid_len, grid, self:
        return BasicShip.move(grid_len, grid, self)
    end
end
