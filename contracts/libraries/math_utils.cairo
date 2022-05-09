%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.models.common import Vector2

namespace math_utils:
    # Return 1 if 'a' is a power of 'b'. Otherwise, return 0
    func is_power_of{range_check_ptr}(a : felt, b : felt) -> (res : felt):
        if b == 1:
            # All integers are a power of 1, as n^0 = 1 for any n
            return (TRUE)
        end
        if a == 0:
            if b == 0:
                # 0 is a power of 0
                return (TRUE)
            end
            # 0 is not a power of anything (but 0)
            return (FALSE)
        end
        if b == 0:
            # Nothing (but 0) is a power of 0
            return (FALSE)
        end

        return _is_power_of_loop(a, b, b)
    end

    func _is_power_of_loop{range_check_ptr}(a : felt, b : felt, multiplier : felt) -> (res : felt):
        if a == b:
            return (TRUE)
        end
        let (a_is_lower_than_b) = is_le(a, b)
        if a_is_lower_than_b == 1:
            return (FALSE)
        end

        return _is_power_of_loop(a, b * multiplier, multiplier)
    end

    # clip a value to the interval [min, max]
    func clamp_value{range_check_ptr}(value, min : felt, max : felt) -> (value : felt):
        assert_lt(min, max)  # min < max

        let (is_lower_than_min) = is_le(value, min)
        if is_lower_than_min == 1:
            return (min)
        end

        let (is_higher_than_max) = is_le(max, value)
        if is_higher_than_max == 1:
            return (max)
        end

        return (value)
    end

    # generate a random number x where min <= x <= max
    func random_in_range{range_check_ptr}(seed : felt, min : felt, max : felt) -> (
        random_value : felt
    ):
        assert_lt(min, max)  # min < max

        let range = max - min + 1
        let (_, value) = unsigned_div_rem(seed, range)  # random in [0, max-min]
        return (value + min)  # random in [min, max]
    end

    # generate a random direction
    func random_direction{range_check_ptr}(seed1 : felt, seed2 : felt) -> (
        random_direction : Vector2
    ):
        alloc_locals
        local random_direction : Vector2

        let (random) = random_in_range(seed1, -1, 1)
        assert random_direction.x = random

        let (random) = random_in_range(seed2, -1, 1)
        assert random_direction.y = random

        return (random_direction=random_direction)
    end
end
