%lang starknet

from contracts.libraries.math_utils import math_utils

@external
func test_9_is_power_of_3{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(9, 3)
    assert res = 1
    return ()
end

@external
func test_128_is_power_of_2{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(128, 2)
    assert res = 1
    return ()
end

@external
func test_100_is_not_power_of_4{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(100, 4)
    assert res = 0
    return ()
end

@external
func test_5_is_not_power_of_17{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(5, 17)
    assert res = 0
    return ()
end

@external
func test_anything_is_power_of_1{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(0, 1)
    assert res = 1
    let (res) = math_utils.is_power_of(1, 1)
    assert res = 1
    let (res) = math_utils.is_power_of(2, 1)
    assert res = 1
    return ()
end

@external
func test_nothing_is_power_of_0_but_0{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(0, 0)
    assert res = 1
    let (res) = math_utils.is_power_of(1, 0)
    assert res = 0
    let (res) = math_utils.is_power_of(2, 0)
    assert res = 0
    return ()
end

@external
func test_0_is_power_of_nothing_but_0_and_1{range_check_ptr}():
    alloc_locals
    let (res) = math_utils.is_power_of(0, 0)
    assert res = 1
    let (res) = math_utils.is_power_of(0, 1)
    assert res = 1
    let (res) = math_utils.is_power_of(0, 2)
    assert res = 0
    return ()
end
