# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from contracts.models.common import ShipInit
from contracts.core.space.library import Space

# ------------------
# EXTERNAL FUNCTIONS
# ------------------

@external
func play_game{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(
        rand_contract_address : felt, size : felt, turn_count : felt, max_dust : felt,
        ships_len : felt, ships : ShipInit*):
    return Space.play_game(rand_contract_address, size, turn_count, max_dust, ships_len, ships)
end
