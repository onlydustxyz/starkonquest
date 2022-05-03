%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.models.common import Vector2, Cell

namespace StaticShip:
    # ---------
    # EXTERNALS
    # ---------

    func move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        grid_state_len : felt, grid_state : Cell*, ship_id : felt
    ) -> (new_direction : Vector2):
        return (Vector2(0, 0))
    end
end
