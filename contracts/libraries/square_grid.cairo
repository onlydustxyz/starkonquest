%lang starknet

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
    member current_cells : Cell*
    member next_cells : Cell*
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
    func create(width : felt) -> (grid : Grid):
        alloc_locals

        local grid : Grid
        assert grid.width = width
        assert grid.cell_count = width * width
        let (cells : Cell*) = alloc()
        assert grid.current_cells = cells
        assert grid.next_cells = cells

        let (empty_cell) = cell_access.create()

        with grid:
            internal.init_cells_loop(grid.current_cells, 0, empty_cell)
            internal.init_cells_loop(grid.next_cells, 0, empty_cell)
        end

        return (grid=grid)
    end

    # Get a given cell in current turn (before apply_modifications)
    # params:
    #   - x, y: The coordinates of the cell to retrieve
    # Returns:
    #   - cell: The cell
    func get_current_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (cell : Cell):
        let (index) = internal.to_grid_index(x, y)
        return (cell=grid.current_cells[index])
    end

    # Get a given cell in next state (after apply_modifications)
    # params:
    #   - x, y: The coordinates of the cell to retrieve
    # Returns:
    #   - cell: The cell
    func get_next_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (cell : Cell):
        let (index) = internal.to_grid_index(x, y)
        return (cell=grid.next_cells[index])
    end

    # Set a given cell in next state (after apply_modifications)
    # params:
    #   - x, y: The coordinates of the cell to retrieve
    #   - new_cell: The new cell value
    func set_next_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, new_cell : Cell):
        alloc_locals
        let (new_cell_index) = internal.to_grid_index(x, y)

        local new_grid : Grid
        assert new_grid.width = grid.width
        assert new_grid.cell_count = grid.cell_count
        assert new_grid.current_cells = grid.current_cells

        let cells : Cell* = alloc()
        assert new_grid.next_cells = cells

        internal.modify_cells_loop(
            grid.next_cells, new_grid.next_cells, 0, new_cell_index, new_cell
        )

        let grid = new_grid
        return ()
    end

    # Apply modifications (next cells move to current cells)
    func apply_modifications{range_check_ptr, grid : Grid}():
        alloc_locals

        local new_grid : Grid
        assert new_grid.width = grid.width
        assert new_grid.cell_count = grid.cell_count
        assert new_grid.current_cells = grid.next_cells
        let (cells : Cell*) = alloc()
        assert new_grid.next_cells = cells

        let (empty_cell) = cell_access.create()
        internal.init_cells_loop(new_grid.next_cells, 0, empty_cell)

        let grid = new_grid
        return ()
    end

    # Generate a random position on a given border (top, left, right, bottom)
    # params:
    #   - r1, r2, r3: Random number seeds
    # returns:
    #   - position(x,y) random position on a border
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

    #
    ####################

    # ------------------
    # PRIVATE NAMESPACE
    # ------------------

    namespace internal:
        func init_cells_loop{grid : Grid}(cells : Cell*, index : felt, init_cell : Cell):
            if index == grid.cell_count:
                return ()
            end

            assert [cells] = init_cell
            init_cells_loop(cells + Cell.SIZE, index + 1, init_cell)
            return ()
        end

        func to_grid_index{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (index : felt):
            with_attr error_message("Out of bound"):
                assert_nn_le(x, grid.width - 1)
                assert_nn_le(y, grid.width - 1)
            end

            let index = y * grid.width + x
            return (index=index)
        end

        func modify_cells_loop{grid : Grid}(
            old_cells : Cell*,
            new_cells : Cell*,
            current_cell_index : felt,
            new_cell_index : felt,
            new_cell : Cell,
        ):
            if current_cell_index == grid.cell_count:
                return ()
            end

            if current_cell_index == new_cell_index:
                assert [new_cells] = new_cell
            else:
                assert [new_cells] = [old_cells]
            end

            return modify_cells_loop(
                old_cells + Cell.SIZE,
                new_cells + Cell.SIZE,
                current_cell_index + 1,
                new_cell_index,
                new_cell,
            )
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
