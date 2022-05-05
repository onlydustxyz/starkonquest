%lang starknet 

from contracts.libraries.square_grid import Grid
from contracts.libraries.cell import Cell

namespace grid_helper:
    func debug_grid{grid: Grid}():
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

            print_cells(ids.grid.current_cells._reference_value, ids.grid.width, ids.Cell.SIZE)
        %}
        return()
    end
end