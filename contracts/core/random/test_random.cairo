%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.core.random.library import Random
from protostar.asserts import assert_not_eq

const BLOCK_NUMBER = 20000;
const BLOCK_TIMESTAMP = 1651498208;
const SEED = 1;

@external
func test_random_generation{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    %{ roll(ids.BLOCK_NUMBER) %}
    %{ warp(ids.BLOCK_TIMESTAMP) %}

    let (r1, r2, r3, r4, r5) = Random.generate_random_numbers(SEED);

    assert_not_eq(r1, r2);
    assert_not_eq(r2, r3);
    assert_not_eq(r3, r4);
    assert_not_eq(r4, r5);

    return ();
}
