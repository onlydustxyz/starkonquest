%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust
from contracts.ships.basic_ship.library import BasicShip
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

func new_dust_cell() -> (cell : Cell):
    let cell = Cell(dust_count=1, dust=Dust(Vector2(1, 0)), ship_id=0)
    return (cell)
end

func new_ship_cell(ship_id : felt) -> (cell : Cell):
    let cell = Cell(dust_count=0, dust=Dust(Vector2(0, 0)), ship_id=ship_id)
    return (cell)
end

@external
func test_no_move_if_no_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (local grid : Grid) = grid_access.create(10)

    %{ expect_revert(error_message="I am lost in space") %}
    BasicShip.move(grid.cell_count, grid.current_cells, 1)

    return ()
end

@external
func test_move_towards_single_dust_above{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(5, 0, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(0, -1)

    return ()
end

@external
func test_move_towards_single_dust_below{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(5, 5, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(0, 1)

    return ()
end

@external
func test_move_towards_single_dust_on_the_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(1, 3, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(-1, 0)

    return ()
end

@external
func test_move_towards_single_dust_on_the_right{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(7, 3, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(1, 0)

    return ()
end

@external
func test_move_towards_single_dust_on_top_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(0, 0, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(-1, -1)

    return ()
end

@external
func test_move_towards_single_dust_on_top_right{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(7, 0, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(1, -1)

    return ()
end

@external
func test_move_towards_single_dust_on_bottom_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(0, 7, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(-1, 1)

    return ()
end

@external
func test_move_towards_single_dust_on_bottom_right{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(9, 7, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(5, 3, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(1, 1)

    return ()
end

@external
func test_move_towards_nearest_dust{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    const SHIP_ID = 1

    let (local grid : Grid) = grid_access.create(10)
    with grid:
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(1, 0, dust_cell)
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(2, 2, dust_cell)
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(3, 4, dust_cell)
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(9, 3, dust_cell)
        let (dust_cell : Cell) = new_dust_cell()
        grid_access.set_next_cell_at(5, 5, dust_cell)

        let (ship_cell : Cell) = new_ship_cell(SHIP_ID)
        grid_access.set_next_cell_at(7, 1, ship_cell)

        grid_access.apply_modifications()
    end

    let (direction : Vector2) = BasicShip.move(grid.cell_count, grid.current_cells, SHIP_ID)
    assert direction = Vector2(1, 1)

    return ()
end
