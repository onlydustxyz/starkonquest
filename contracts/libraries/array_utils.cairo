%lang starknet

from starkware.cairo.common.math_cmp import is_le
from contracts.models.common import Vector2

namespace array_utils:
    # Return the index of the highest element in array. Negative numbers underflow, so they are not actually handled as negative numbers.
    func get_highest_element_index{range_check_ptr, array_len : felt, array : felt*}() -> (
        highest_element_index : felt
    ):
        let (highest_element_index) = _get_highest_element_index_loop(0, 0, 0)
        return (highest_element_index)
    end

    func _get_highest_element_index_loop{range_check_ptr, array_len : felt, array : felt*}(
        current_highest_element_index : felt, current_highest_element : felt, index : felt
    ) -> (highest_index : felt):
        if index == array_len:
            return (current_highest_element_index)
        end

        let element = array[index]
        let (element_is_higher) = is_le(current_highest_element + 1, element)
        if element_is_higher == 1:
            return _get_highest_element_index_loop(index, element, index + 1)
        end
        return _get_highest_element_index_loop(
            current_highest_element_index, current_highest_element, index + 1
        )
    end
end
