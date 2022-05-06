%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.models.common import Vector2
from contracts.libraries.cell import Cell
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number
from contracts.interfaces.irand import IRandom
from contracts.core.library import MathUtils_random_direction

# ------------
# STORAGE VARS
# ------------

@storage_var
func random_contract() -> (random_contract : felt):
end

namespace RandomMoveShip:
    func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        random_contract_ : felt
    ) -> ():
        random_contract.write(random_contract_)
        return ()
    end

    # ---------
    # EXTERNALS
    # ---------

    func move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        grid_state_len : felt, grid_state : Cell*, ship_id : felt
    ) -> (new_direction : Vector2):
        let (random_contract_address) = random_contract.read()
        let (block_timestamp) = get_block_timestamp()
        let (r1, r2, _, _, _) = IRandom.generate_random_numbers(
            random_contract_address, block_timestamp
        )
        let (random_direction) = MathUtils_random_direction(r1, r2)

        return (new_direction=random_direction)
    end
end
