%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.core.random.library import Random

@view
func generate_random_numbers{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(seed: felt) -> (r1: felt, r2: felt, r3: felt, r4: felt, r5: felt) {
    return Random.generate_random_numbers(seed);
}
