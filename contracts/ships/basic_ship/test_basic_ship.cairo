%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.interfaces.icell import cell_access, Cell, Dust
from contracts.ships.basic_ship.library import BasicShip
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from contracts.test.grid_helper import grid_helper
from contracts.test.standard_cell import StandardCell

func new_dust_cell() -> (cell: Cell) {
    let cell_class_hash = StandardCell.class_hash();
    let cell = Cell(cell_class_hash, dust_count=1, dust=Dust(Vector2(1, 0)), ship_id=0);
    return (cell,);
}

func new_ship_cell(ship_id: felt) -> (cell: Cell) {
    let cell_class_hash = StandardCell.class_hash();
    let cell = Cell(cell_class_hash, dust_count=0, dust=Dust(Vector2(0, 0)), ship_id=ship_id);
    return (cell,);
}

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    StandardCell.declare();
    return ();
}

@external
func test_no_move_if_no_dust{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);

    %{ expect_revert(error_message="I am lost in space") %}
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    // BasicShip.move(grid.cell_count, grid.current_cells, 1)
    BasicShip.move(grid.cell_count, cell_array, 1);

    return ();
}

@external
func test_move_towards_single_dust_above{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(5, 0, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }

    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(0, -1);

    return ();
}

@external
func test_move_towards_single_dust_below{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(5, 5, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(0, 1);

    return ();
}

@external
func test_move_towards_single_dust_on_the_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(1, 3, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        grid_access.apply_modifications();
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(-1, 0);

    return ();
}

@external
func test_move_towards_single_dust_on_the_right{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(7, 3, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(1, 0);

    return ();
}

@external
func test_move_towards_single_dust_on_top_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(0, 0, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(-1, -1);

    return ();
}

@external
func test_move_towards_single_dust_on_top_right{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(7, 0, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(1, -1);

    return ();
}

@external
func test_move_towards_single_dust_on_bottom_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(0, 7, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(-1, 1);

    return ();
}

@external
func test_move_towards_single_dust_on_bottom_right{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(9, 7, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(5, 3, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(1, 1);

    return ();
}

@external
func test_move_towards_nearest_dust{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    const SHIP_ID = 1;

    let cell_class_hash = StandardCell.class_hash();
    let (local grid: Grid) = grid_access.create(cell_class_hash, 10);
    with grid {
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(1, 0, dust_cell);
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(2, 2, dust_cell);
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(3, 4, dust_cell);
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(9, 3, dust_cell);
        let (dust_cell: Cell) = new_dust_cell();
        grid_access.set_cell_at(5, 5, dust_cell);

        let (ship_cell: Cell) = new_ship_cell(SHIP_ID);
        grid_access.set_cell_at(7, 1, ship_cell);

        // grid_access.apply_modifications()
    }
    let (cell_array: Cell*) = alloc();
    with grid {
        grid_helper.dict_to_array(cell_array, 0);
    }
    let (direction: Vector2) = BasicShip.move(grid.cell_count, cell_array, SHIP_ID);
    assert direction = Vector2(1, 1);

    return ();
}
