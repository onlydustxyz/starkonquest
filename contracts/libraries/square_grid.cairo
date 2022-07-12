%lang starknet

from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.registers import get_fp_and_pc

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le

from contracts.models.common import Vector2
from contracts.libraries.math_utils import math_utils
from contracts.libraries.cell import Cell, cell_access

# ------------------
# STRUCTS
# ------------------

struct Grid:
    member width : felt
    member cell_count : felt
    member cells_start : DictAccess*
    member cells_end : DictAccess*
end

# ------------------
# PUBLIC NAMESPACE
# ------------------

namespace grid_access:
    # Create a new square grid of width*width cells stored in a single-dimension array
    # params:
    #   - width: The number of rows/columns
    # returns:
    #   - grid: The created grid
    func create{range_check_ptr}(width : felt) -> (grid : Grid):
        alloc_locals

        local grid : Grid
        assert grid.width = width
        assert grid.cell_count = width * width

        let (local empty_cell) = cell_access.create()
        let (__fp__, _) = get_fp_and_pc()

        let (local my_dict_start) = default_dict_new(default_value=0)
        let my_dict = my_dict_start
        let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(
            my_dict_start, my_dict, 0
        )
        # ALLOC

        assert grid.cells_start = my_dict  # finalized_dict_start
        assert grid.cells_end = my_dict + grid.cell_count * DictAccess.SIZE
        with grid:
            internal.init_cells_loop(grid.cells_start, 0, &empty_cell)
        end

        return (grid=grid)
    end

    # Get a given cell in current turn (before apply_modifications)
    # params:
    #   - x, y: The coordinates of the cell to retrieve
    # Returns:
    #   - cell: The cell

    func get_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (cell : Cell):
        alloc_locals
        let (index) = internal.to_grid_index(x, y)

        let current_cells_dict_end_ptr = grid.cells_end

        let (local val : Cell*) = dict_read{dict_ptr=current_cells_dict_end_ptr}(key=index)
        local new_grid : Grid
        new_grid.width = grid.width
        new_grid.cell_count = grid.cell_count
        new_grid.cells_start = grid.cells_start
        new_grid.cells_end = current_cells_dict_end_ptr  # This ptr was moved to the last entry by dict_read
        let grid = new_grid

        return (cell=[val])
    end

    func get_cell_at_index{range_check_ptr, grid : Grid}(index : felt) -> (cell : Cell):
        alloc_locals
        let current_cells_dict_end_ptr = grid.cells_end

        let (local val : Cell*) = dict_read{dict_ptr=current_cells_dict_end_ptr}(key=index)
        local new_grid : Grid
        new_grid.width = grid.width
        new_grid.cell_count = grid.cell_count
        new_grid.cells_start = grid.cells_start
        new_grid.cells_end = current_cells_dict_end_ptr  # This ptr was moved to the last entry by dict_read
        let grid = new_grid

        return (cell=[val])
    end
    # Set a given cell in next state (after apply_modifications)
    # params:
    #   - x, y: The coordinates of the cell to retrieve
    #   - new_cell: The new cell value
    func set_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, new_cell : Cell):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()

        let (new_cell_index) = internal.to_grid_index(x, y)
        let cells_end_ptr = grid.cells_end

        local new_grid : Grid
        assert new_grid.width = grid.width
        assert new_grid.cell_count = grid.cell_count
        assert new_grid.cells_start = grid.cells_start
        dict_write{dict_ptr=cells_end_ptr}(key=new_cell_index, new_value=cast(&new_cell, felt))

        assert new_grid.cells_end = cells_end_ptr

        let grid = new_grid
        return ()
    end
    # Apply modifications (squash grid dict)
    func apply_modifications{range_check_ptr, grid : Grid}():
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()

        local new_grid : Grid
        assert new_grid.width = grid.width
        assert new_grid.cell_count = grid.cell_count
        let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(
            grid.cells_start, grid.cells_end, 0
        )
        assert new_grid.cells_start = finalized_dict_start
        assert new_grid.cells_end = finalized_dict_end

        let grid = new_grid
        return ()
    end
    func generate_random_position_on_border{range_check_ptr, grid : Grid}(r1, r2, r3) -> (
        position : Vector2
    ):
        alloc_locals

        # x is 0 or grid.width - 1
        let (x) = math_utils.random_in_range(r1, 0, 1)
        local x = x * (grid.width - 1)

        # y is in [0, grid.width-1]
        let (y) = math_utils.random_in_range(r2, 0, grid.width - 1)

        let (position) = internal.shuffled_position(x, y, r3)
        return (position=position)
    end
    # Return a couple of booleans that will be true of the givent position in on the border
    func is_crossing_border{grid : Grid}(position : Vector2, direction : Vector2) -> (
        crossing_border : Vector2
    ):
        alloc_locals

        let (local crossing_border_x) = internal.is_crossing_border(position.x, direction.x)
        let (crossing_border_y) = internal.is_crossing_border(position.y, direction.y)
        return (crossing_border=Vector2(crossing_border_x, crossing_border_y))
    end

    ####################
    # Iterator pattern

    # Return the first cell coordinates
    func start{grid : Grid}() -> (grid_iterator : Vector2):
        return (grid_iterator=Vector2(0, 0))
    end

    # Return the next cell coordinates
    func next{grid : Grid, grid_iterator : Vector2}():
        if grid_iterator.x == grid.width - 1:
            let grid_iterator = Vector2(0, grid_iterator.y + 1)
            return ()
        end

        let grid_iterator = Vector2(grid_iterator.x + 1, grid_iterator.y)
        return ()
    end

    # Return the next cell coordinates
    func done{grid : Grid, grid_iterator : Vector2}() -> (is_done : felt):
        if grid_iterator.y == grid.width:
            return (is_done=1)
        end
        return (is_done=0)
    end

    namespace internal:
        func to_grid_index{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (index : felt):
            with_attr error_message("Out of bound"):
                assert_nn_le(x, grid.width - 1)
                assert_nn_le(y, grid.width - 1)
            end

            let index = y * grid.width + x
            return (index=index)
        end

        func init_cells_loop{grid : Grid, range_check_ptr}(
            end_cells : DictAccess*, index : felt, init_cell : Cell*
        ):
            alloc_locals
            if index == grid.cell_count:
                # -1 ?
                return ()
            end

            dict_write{dict_ptr=end_cells}(key=index, new_value=cast(init_cell, felt))

            init_cells_loop(end_cells, index + 1, init_cell)
            return ()
        end
        # given x, y return randomly Position(x,y) or Position(y,x)
        func shuffled_position{range_check_ptr}(x : felt, y : felt, r) -> (position : Vector2):
            alloc_locals
            local position : Vector2

            let (on_horizontal_border) = math_utils.random_in_range(r, 0, 1)
            if on_horizontal_border == 0:
                assert position.x = x
                assert position.y = y
            else:
                assert position.x = y
                assert position.y = x
            end

            return (position=position)
        end
        func is_crossing_border{grid : Grid}(position : felt, direction : felt) -> (
            crossing_border : felt
        ):
            if position == 0:
                if direction == -1:
                    return (crossing_border=1)
                end
            end

            if position == grid.width - 1:
                if direction == 1:
                    return (crossing_border=1)
                end
            end

            return (crossing_border=0)
        end
    end
end
