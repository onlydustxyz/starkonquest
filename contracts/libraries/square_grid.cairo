%lang starknet

from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.memcpy import memcpy

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_nn_le

from contracts.models.common import Vector2
from contracts.libraries.math_utils import math_utils
from contracts.interfaces.icell import Cell, cell_access

// ------------------
// STRUCTS
// ------------------

struct Grid {
    width: felt,
    cell_count: felt,
    cells_start: DictAccess*,
    cells_end: DictAccess*,
    ships_positions_len: felt,
    ships_positions: Vector2*,
    dusts_positions_len: felt,
    dusts_positions: Vector2*,
}

// ------------------
// PUBLIC NAMESPACE
// ------------------

namespace grid_access {
    // Create a new square grid of width*width cells stored in a single-dimension array
    // params:
    //   - width: The number of rows/columns
    // returns:
    //   - grid: The created grid
    func create{syscall_ptr: felt*, range_check_ptr}(cell_class_hash: felt, width: felt) -> (
        grid: Grid
    ) {
        alloc_locals;

        local grid: Grid;
        assert grid.width = width;
        assert grid.cell_count = width * width;

        let (ships_positions: Vector2*) = alloc();
        let (dusts_positions: Vector2*) = alloc();

        assert grid.ships_positions_len = 0;
        assert grid.ships_positions = ships_positions;

        assert grid.dusts_positions_len = 0;
        assert grid.dusts_positions = dusts_positions;

        let (local empty_cell) = cell_access.create(cell_class_hash);
        let (__fp__, _) = get_fp_and_pc();

        let (local my_dict_start) = default_dict_new(default_value=0);
        let my_dict = my_dict_start;
        let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(
            my_dict_start, my_dict, 0
        );

        assert grid.cells_start = my_dict;
        assert grid.cells_end = my_dict + grid.cell_count * DictAccess.SIZE;
        with grid {
            internal.init_cells_loop(grid.cells_start, 0, &empty_cell);
        }

        return (grid=grid);
    }

    // Get a given cell in current turn
    // params:
    //   - x, y: The coordinates of the cell to retrieve
    // Returns:
    //   - cell: The cell

    func get_cell_at{range_check_ptr, grid: Grid}(x: felt, y: felt) -> (cell: Cell) {
        alloc_locals;
        let (index) = internal.to_grid_index(x, y);

        let cells_end_ptr = grid.cells_end;

        let (local val: Cell*) = dict_read{dict_ptr=cells_end_ptr}(key=index);
        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = cells_end_ptr;  // This ptr was moved to the last entry by dict_read
        assert new_grid.ships_positions = grid.ships_positions;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions_len = grid.dusts_positions_len;
        let grid = new_grid;

        return (cell=[val]);
    }

    func get_cell_at_index{range_check_ptr, grid: Grid}(index: felt) -> (cell: Cell) {
        alloc_locals;
        let cells_end_ptr = grid.cells_end;

        let (local val: Cell*) = dict_read{dict_ptr=cells_end_ptr}(key=index);
        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = cells_end_ptr;  // This ptr was moved to the last entry by dict_read
        assert new_grid.ships_positions = grid.ships_positions;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions_len = grid.dusts_positions_len;
        let grid = new_grid;

        return (cell=[val]);
    }

    func set_cell_at{range_check_ptr, grid: Grid}(x: felt, y: felt, new_cell: Cell) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (new_cell_index) = internal.to_grid_index(x, y);
        let cells_end_ptr = grid.cells_end;

        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        dict_write{dict_ptr=cells_end_ptr}(key=new_cell_index, new_value=cast(&new_cell, felt));

        assert new_grid.cells_end = cells_end_ptr;
        assert new_grid.ships_positions = grid.ships_positions;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions_len = grid.dusts_positions_len;

        let grid = new_grid;
        return ();
    }
    // Apply modifications (squash grid dict)
    func apply_modifications{range_check_ptr, grid: Grid}() {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(
            grid.cells_start, grid.cells_end, 0
        );
        assert new_grid.cells_start = finalized_dict_start;
        assert new_grid.cells_end = finalized_dict_end;
        assert new_grid.ships_positions = grid.ships_positions;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions_len = grid.dusts_positions_len;

        let grid = new_grid;
        return ();
    }

    func add_ship_position{range_check_ptr, grid: Grid}(ship_position: Vector2) {
        alloc_locals;
        local new_grid: Grid;

        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = grid.cells_end;

        assert new_grid.ships_positions_len = grid.ships_positions_len + 1;
        assert new_grid.ships_positions = grid.ships_positions;
        assert new_grid.ships_positions[grid.ships_positions_len] = ship_position;

        assert new_grid.dusts_positions_len = grid.dusts_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;

        let grid = new_grid;
        return ();
    }

    func update_ship_position_at_index{range_check_ptr, grid: Grid}(
        index: felt, new_ship_position: Vector2
    ) {
        alloc_locals;
        assert_nn_le(index, grid.ships_positions_len - 1);

        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = grid.cells_end;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions_len = grid.dusts_positions_len;

        let (new_ships_positions: Vector2*) = alloc();
        update_ship_position_at_index_loop(
            0,
            index,
            grid.ships_positions_len,
            grid.ships_positions,
            new_ships_positions,
            new_ship_position,
        );
        assert new_grid.ships_positions = new_ships_positions;
        let grid = new_grid;
        return ();
    }
    func update_ship_position_at_index_loop{range_check_ptr, grid: Grid}(
        cursor: felt,
        index: felt,
        ships_positions_len: felt,
        ships_positions: Vector2*,
        new_ships_positions: Vector2*,
        new_ship_position: Vector2,
    ) {
        alloc_locals;
        if (cursor == ships_positions_len) {
            return ();
        }

        if (cursor == index) {
            assert new_ships_positions[cursor] = new_ship_position;
            return update_ship_position_at_index_loop(
                cursor + 1,
                index,
                ships_positions_len,
                ships_positions,
                new_ships_positions,
                new_ship_position,
            );
        }

        assert new_ships_positions[cursor] = ships_positions[cursor];
        return update_ship_position_at_index_loop(
            cursor + 1,
            index,
            ships_positions_len,
            ships_positions,
            new_ships_positions,
            new_ship_position,
        );
    }

    func add_dust_position{syscall_ptr: felt*, range_check_ptr, grid: Grid}(
        dust_position: Vector2
    ) {
        alloc_locals;
        let (local cell) = grid_access.get_cell_at(dust_position.x, dust_position.y);
        let (has_dust) = cell_access.has_dust{cell=cell}();
        if (has_dust == 1) {
            // If the cell at this position already has dust, the position should already be in grid.dusts_positions, no need to add a new one.
            return ();
        }
        local new_grid: Grid;

        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = grid.cells_end;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.ships_positions = grid.ships_positions;

        assert new_grid.dusts_positions_len = grid.dusts_positions_len + 1;
        assert new_grid.dusts_positions = grid.dusts_positions;
        assert new_grid.dusts_positions[grid.dusts_positions_len] = dust_position;

        let grid = new_grid;

        return ();
    }
    func update_dust_position_at_index{
        syscall_ptr: felt*, range_check_ptr, grid: Grid, dust_merged_count: felt
    }(index: felt, new_dust_position: Vector2) {
        alloc_locals;
        assert_nn_le(index, grid.dusts_positions_len - 1);
        let (local cell) = grid_access.get_cell_at(new_dust_position.x, new_dust_position.y);
        let (has_dust_at_new_position) = cell_access.has_dust{cell=cell}();

        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = grid.cells_end;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.ships_positions = grid.ships_positions;

        assert new_grid.dusts_positions_len = grid.dusts_positions_len - has_dust_at_new_position;

        let (new_dusts_positions: Vector2*) = alloc();
        update_dust_position_at_index_loop(
            0,
            0,
            index,
            grid.dusts_positions_len,
            grid.dusts_positions,
            new_dusts_positions,
            new_dust_position,
            has_dust_at_new_position,
        );
        assert new_grid.dusts_positions = new_dusts_positions;
        let grid = new_grid;
        return ();
    }
    func update_dust_position_at_index_loop{range_check_ptr, grid: Grid, dust_merged_count: felt}(
        cursor: felt,
        new_cursor: felt,
        index: felt,
        dusts_positions_len: felt,
        dusts_positions: Vector2*,
        new_dusts_positions: Vector2*,
        new_dust_position: Vector2,
        has_dust_at_new_position: felt,
    ) {
        alloc_locals;
        if (cursor == dusts_positions_len) {
            return ();
        }

        if (cursor == index) {
            if (has_dust_at_new_position == 1) {
                let dust_merged_count = dust_merged_count + 1;
                return update_dust_position_at_index_loop(
                    cursor + 1,
                    new_cursor,
                    index,
                    dusts_positions_len,
                    dusts_positions,
                    new_dusts_positions,
                    new_dust_position,
                    has_dust_at_new_position,
                );
            }
            assert new_dusts_positions[new_cursor] = new_dust_position;
            return update_dust_position_at_index_loop(
                cursor + 1,
                new_cursor + 1,
                index,
                dusts_positions_len,
                dusts_positions,
                new_dusts_positions,
                new_dust_position,
                has_dust_at_new_position,
            );
        }

        assert new_dusts_positions[new_cursor] = dusts_positions[cursor];
        return update_dust_position_at_index_loop(
            cursor + 1,
            new_cursor + 1,
            index,
            dusts_positions_len,
            dusts_positions,
            new_dusts_positions,
            new_dust_position,
            has_dust_at_new_position,
        );
    }
    func remove_dust_position_at_index{range_check_ptr, grid: Grid}(index: felt) {
        alloc_locals;
        local new_grid: Grid;
        assert new_grid.width = grid.width;
        assert new_grid.cell_count = grid.cell_count;
        assert new_grid.cells_start = grid.cells_start;
        assert new_grid.cells_end = grid.cells_end;
        assert new_grid.ships_positions_len = grid.ships_positions_len;
        assert new_grid.ships_positions = grid.ships_positions;

        assert new_grid.dusts_positions_len = grid.dusts_positions_len - 1;
        let (new_dusts_positions: Vector2*) = alloc();

        memcpy(new_dusts_positions, grid.dusts_positions, index * Vector2.SIZE);
        memcpy(
            new_dusts_positions + index * Vector2.SIZE,
            grid.dusts_positions + (index + 1) * Vector2.SIZE,
            (grid.dusts_positions_len - index - 1) * Vector2.SIZE,
        );
        assert new_grid.dusts_positions = new_dusts_positions;
        let grid = new_grid;
        return ();
    }
    func remove_dust_position_value{range_check_ptr, grid: Grid}(value: Vector2) {
        alloc_locals;
        let (index) = grid_access.find_dust_index_loop(
            grid.dusts_positions_len, grid.dusts_positions, value, 0
        );
        grid_access.remove_dust_position_at_index(index);
        return ();
    }

    func find_dust_index_loop{range_check_ptr}(
        dusts_positions_len: felt, dusts_positions: Vector2*, value: Vector2, cursor: felt
    ) -> (index: felt) {
        alloc_locals;
        if (cursor == dusts_positions_len) {
            return (index=dusts_positions_len + 1);
        }
        let pos = dusts_positions[cursor];
        if (pos.x == value.x) {
            if (pos.y == value.y) {
                return (index=cursor);
            }
        }

        return find_dust_index_loop(dusts_positions_len, dusts_positions, value, cursor + 1);
    }

    func generate_random_position_on_border{range_check_ptr, grid: Grid}(r1, r2, r3) -> (
        position: Vector2
    ) {
        alloc_locals;

        // x is 0 or grid.width - 1
        let (x) = math_utils.random_in_range(r1, 0, 1);
        local x = x * (grid.width - 1);

        // y is in [0, grid.width-1]
        let (y) = math_utils.random_in_range(r2, 0, grid.width - 1);

        let (position) = internal.shuffled_position(x, y, r3);
        return (position=position);
    }
    // Return a couple of booleans that will be true of the givent position in on the border
    func is_crossing_border{grid: Grid}(position: Vector2, direction: Vector2) -> (
        crossing_border: Vector2
    ) {
        alloc_locals;

        let (local crossing_border_x) = internal.is_crossing_border(position.x, direction.x);
        let (crossing_border_y) = internal.is_crossing_border(position.y, direction.y);
        return (crossing_border=Vector2(crossing_border_x, crossing_border_y));
    }

    //###################
    // Iterator pattern

    // Return the first cell coordinates
    func start{grid: Grid}() -> (grid_iterator: Vector2) {
        return (grid_iterator=Vector2(0, 0));
    }

    // Return the next cell coordinates
    func next{grid: Grid, grid_iterator: Vector2}() {
        if (grid_iterator.x == grid.width - 1) {
            let grid_iterator = Vector2(0, grid_iterator.y + 1);
            return ();
        }

        let grid_iterator = Vector2(grid_iterator.x + 1, grid_iterator.y);
        return ();
    }

    // Return the next cell coordinates
    func done{grid: Grid, grid_iterator: Vector2}() -> (is_done: felt) {
        if (grid_iterator.y == grid.width) {
            return (is_done=1);
        }
        return (is_done=0);
    }

    namespace internal {
        func to_grid_index{range_check_ptr, grid: Grid}(x: felt, y: felt) -> (index: felt) {
            with_attr error_message("Out of bound") {
                assert_nn_le(x, grid.width - 1);
                assert_nn_le(y, grid.width - 1);
            }

            let index = y * grid.width + x;
            return (index=index);
        }

        func init_cells_loop{grid: Grid, range_check_ptr}(
            end_cells: DictAccess*, index: felt, init_cell: Cell*
        ) {
            alloc_locals;
            if (index == grid.cell_count) {
                // -1 ?
                return ();
            }

            dict_write{dict_ptr=end_cells}(key=index, new_value=cast(init_cell, felt));

            init_cells_loop(end_cells, index + 1, init_cell);
            return ();
        }
        // given x, y return randomly Position(x,y) or Position(y,x)
        func shuffled_position{range_check_ptr}(x: felt, y: felt, r) -> (position: Vector2) {
            alloc_locals;
            local position: Vector2;

            let (on_horizontal_border) = math_utils.random_in_range(r, 0, 1);
            if (on_horizontal_border == 0) {
                assert position.x = x;
                assert position.y = y;
            } else {
                assert position.x = y;
                assert position.y = x;
            }

            return (position=position);
        }
        func is_crossing_border{grid: Grid}(position: felt, direction: felt) -> (
            crossing_border: felt
        ) {
            if (position == 0) {
                if (direction == -1) {
                    return (crossing_border=1);
                }
            }

            if (position == grid.width - 1) {
                if (direction == 1) {
                    return (crossing_border=1);
                }
            }

            return (crossing_border=0);
        }
    }
}
