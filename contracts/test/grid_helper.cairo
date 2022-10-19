%lang starknet

from contracts.libraries.square_grid import Grid, grid_access
from contracts.interfaces.icell import Cell
from starkware.cairo.common.alloc import alloc

namespace grid_helper {
    func debug_grid{range_check_ptr, grid: Grid}() {
        alloc_locals;
        let (local dbg_cell_array: Cell*) = alloc();
        dict_to_array(dbg_cell_array, 0);

        %{
            def display(cell):
                dust = memory[cell] > 0 
                ship = memory[cell+3]
                return str(ship) if ship > 0 else '*' if dust else ' '

            def print_cells(cells, grid_width, cell_size):
                print()
                print('+' + '-'*grid_width + '+')
                for r in range(grid_width):
                    disp_row = []
                    for c in range(grid_width):
                        disp_row.append(display(cells))
                        cells += cell_size
                    print('|' + ''.join(disp_row) + '|')
                print('+' + '-'*grid_width + '+')

            print_cells(ids.dbg_cell_array._reference_value, ids.grid.width, ids.Cell.SIZE)
        %}
        return ();
    }
    func dict_to_array{range_check_ptr, grid: Grid}(array: Cell*, index: felt) {
        if (index == grid.cell_count) {
            return ();
        }
        let cell: Cell = grid_access.get_cell_at_index(index);
        assert [array] = cell;
        dict_to_array(array + Cell.SIZE, index + 1);
        return ();
    }
}
