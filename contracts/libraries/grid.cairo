%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.models.common import Vector2, Dust, Cell, Context, Grid
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.math_cmp import is_not_zero
from contracts.core.library import MathUtils_random_in_range

namespace grid_manip:
    # Create a new square grid of size*size cells stored in a single-dimension array
    # params:
    #   - grid_size: The number of rows/columns
    # returns:
    #   - grid: The created grid
    func create(size : felt) -> (grid : Grid):
        alloc_locals

        local grid : Grid
        assert grid.size = size
        assert grid.nb_cells = size * size
        let (new_cells : Cell*) = alloc()
        assert grid.cells = new_cells

        let empty_cell = Cell(Dust(FALSE, Vector2(0, 0)), 0)

        internal.init_grid_loop(grid, 0, empty_cell)

        return (grid=grid)
    end

    # Set a dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    #   - dust: The dust to set
    func set_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
        let (ship_id) = get_ship_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, ship_id))
    end

    # Get the dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    # Returns:
    #   - dust: The dust to set
    func get_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (dust : Dust):
        let (cell) = internal.get_cell_at(x, y)
        return (dust=cell.dust)
    end

    # Remove a dust on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    func clear_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
        let (ship_id) = get_ship_at(x, y)
        let NO_DUST = Dust(FALSE, Vector2(0, 0))
        return internal.set_cell_at(x, y, Cell(NO_DUST, ship_id))
    end

    # Set a ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    #   - ship_id: The ship to set
    func set_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt, ship_id : felt):
        let (dust) = get_dust_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, ship_id))
    end

    # Get the ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    # Returns:
    #   - ship_id: The ship to set
    func get_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (ship_id : felt):
        let (cell) = internal.get_cell_at(x, y)
        return (ship_id=cell.ship_id)
    end

    # Remove a ship on a given cell
    # params:
    #   - x, y: The coordinates of the cell to modify
    func clear_ship_at{range_check_ptr, grid : Grid}(x : felt, y : felt):
        let NO_SHIP = 0
        let (dust) = get_dust_at(x, y)
        return internal.set_cell_at(x, y, Cell(dust, NO_SHIP))
    end

    # Check if a given cell is occupied (contains a dust and/or a ship)
    # params:
    #   - x, y: The coordinates of the cell to check
    # returns:
    #   - 1 if the cell is occupied, 0 otherwise
    func is_cell_occupied{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (
        cell_is_occupied : felt
    ):
        let (cell) = internal.get_cell_at(x, y)
        let (cell_is_occupied) = is_not_zero(cell.dust.present + cell.ship_id)
        return (cell_is_occupied=cell_is_occupied)
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

        # x is 0 or grid.size - 1
        let (x) = MathUtils_random_in_range(r1, 0, 1)
        local x = x * (grid.size - 1)

        # y is in [0, grid.size-1]
        let (y) = MathUtils_random_in_range(r2, 0, grid.size - 1)

        let (position) = internal.shuffled_position(x, y, r3)
        return (position=position)
    end

    namespace internal:
        func init_grid_loop(grid : Grid, index : felt, init_cell : Cell):
            if index == grid.nb_cells:
                return ()
            end

            assert grid.cells[index] = init_cell
            init_grid_loop(grid, index + 1, init_cell)
            return ()
        end

        func to_grid_index{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (index : felt):
            let index = y * grid.size + x
            with_attr error_message("Out of bound"):
                assert_nn_le(index, grid.nb_cells)
            end

            return (index=index)
        end

        func get_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt) -> (cell : Cell):
            let (index) = to_grid_index(x, y)
            return (cell=grid.cells[index])
        end

        func set_cell_at{range_check_ptr, grid : Grid}(x : felt, y : felt, new_cell : Cell):
            alloc_locals
            let (new_cell_index) = to_grid_index(x, y)

            local new_grid : Grid
            assert new_grid.size = grid.size
            assert new_grid.nb_cells = grid.nb_cells

            let new_cells : Cell* = alloc()
            assert new_grid.cells = new_cells

            modify_grid_loop(new_grid, 0, new_cell_index, new_cell)

            let grid = new_grid
            return ()
        end

        func modify_grid_loop{grid : Grid}(
            new_grid : Grid, current_cell_index : felt, new_cell_index : felt, new_cell : Cell
        ):
            if current_cell_index == grid.nb_cells:
                return ()
            end

            if current_cell_index == new_cell_index:
                assert new_grid.cells[current_cell_index] = new_cell
            else:
                assert new_grid.cells[current_cell_index] = grid.cells[current_cell_index]
            end

            return modify_grid_loop(new_grid, current_cell_index + 1, new_cell_index, new_cell)
        end

        # given x, y return randomly Position(x,y) or Position(y,x)
        func shuffled_position{range_check_ptr}(x : felt, y : felt, r) -> (position : Vector2):
            alloc_locals
            local position : Vector2

            let (on_horizontal_border) = MathUtils_random_in_range(r, 0, 1)
            if on_horizontal_border == 0:
                assert position.x = x
                assert position.y = y
            else:
                assert position.x = y
                assert position.y = x
            end

            return (position=position)
        end
    end
end
