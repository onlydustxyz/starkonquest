%lang starknet

from contracts.libraries.array_utils import array_utils

@external
func test_get_highest_element_index{range_check_ptr}():
    alloc_locals
    let (res) = array_utils.get_highest_element_index(3, new (1, 2, 3))
    assert res = 2
    let (res) = array_utils.get_highest_element_index(3, new (3, 2, 1))
    assert res = 0
    let (res) = array_utils.get_highest_element_index(3, new (2, 3, 1))
    assert res = 1
    return ()
end

@external
func test_get_highest_element_index_empty_array{range_check_ptr}():
    alloc_locals
    let (res) = array_utils.get_highest_element_index(0, new ())
    assert res = 0
    return ()
end

func test_get_highest_element_index_with_identical_values{range_check_ptr}():
    alloc_locals
    let (res) = array_utils.get_highest_element_index(4, new (1, 2, 1, 2))
    assert res = 1
    return ()
end
