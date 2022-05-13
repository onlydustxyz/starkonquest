%lang starknet

from contracts.libraries.array_utils import array_utils

@external
func test_get_highest_element_index{range_check_ptr}():
    alloc_locals

    tempvar array_len = 3
    tempvar array : felt* = new (1, 2, 3)
    let (res) = array_utils.get_highest_element_index{array_len=array_len, array=array}()
    assert res = 2

    tempvar array_len = 3
    tempvar array : felt* = new (3, 2, 1)
    let (res) = array_utils.get_highest_element_index{array_len=array_len, array=array}()
    assert res = 0

    tempvar array_len = 3
    tempvar array : felt* = new (2, 3, 1)
    let (res) = array_utils.get_highest_element_index{array_len=array_len, array=array}()
    assert res = 1
    return ()
end

@external
func test_get_highest_element_index_empty_array{range_check_ptr}():
    alloc_locals
    tempvar array_len = 0
    tempvar array : felt* = new ()
    let (res) = array_utils.get_highest_element_index{array_len=array_len, array=array}()
    assert res = 0
    return ()
end

func test_get_highest_element_index_with_identical_values{range_check_ptr}():
    alloc_locals
    tempvar array_len = 4
    tempvar array : felt* = new (1, 2, 1, 2)
    let (res) = array_utils.get_highest_element_index{array_len=array_len, array=array}()
    assert res = 1
    return ()
end
