%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.core.random.library import Random

@view
func generate_random_numbers{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(seed : felt) -> (r1, r2, r3, r4, r5):
    return Random.generate_random_numbers(seed)
end
