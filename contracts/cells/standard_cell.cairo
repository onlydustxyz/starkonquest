%lang starknet

from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero

from contracts.models.common import Vector2
from contracts.interfaces.icell import Dust, Cell

// ------------------
// ICell implementation
// ------------------

// create an empty cell
@view
func create(cell_class_hash: felt) -> (cell: Cell) {
    alloc_locals;

    local cell: Cell;
    assert cell.class_hash = cell_class_hash;
    assert cell.dust_count = 0;
    assert cell.dust.direction = Vector2(0, 0);
    assert cell.ship_id = 0;

    return (cell=cell);
}

// Add a ship in a given cell
@view
func add_ship(cell: Cell, ship_id: felt) -> (cell: Cell) {
    alloc_locals;

    let (ship_exists) = has_ship(cell);
    with_attr error_message("Cell: There is already a ship") {
        assert ship_exists = 0;
    }

    local new_cell: Cell;
    assert new_cell.class_hash = cell.class_hash;
    assert new_cell.dust_count = cell.dust_count;
    assert new_cell.dust.direction = cell.dust.direction;
    assert new_cell.ship_id = ship_id;

    return (cell=new_cell);
}

// Remove a ship in a given cell
@view
func remove_ship(cell: Cell) -> (cell: Cell) {
    alloc_locals;

    let (ship_exists) = has_ship(cell);
    with_attr error_message("Cell: No ship here") {
        assert_not_zero(ship_exists);
    }

    local new_cell: Cell;
    assert new_cell.class_hash = cell.class_hash;
    assert new_cell.dust_count = cell.dust_count;
    assert new_cell.dust.direction = cell.dust.direction;
    assert new_cell.ship_id = 0;

    return (cell=new_cell);
}

// Get a ship on a given cell
@view
func get_ship(cell: Cell) -> (ship_id: felt) {
    return (ship_id=cell.ship_id);
}

// Check if a given cell contains a ship
@view
func has_ship(cell: Cell) -> (has_ship: felt) {
    let (ship_id) = get_ship(cell);
    let has_ship = is_not_zero(ship_id);
    return (has_ship=has_ship);
}

// Add a dust in a given cell
// ! Adding a dust will increment the dust count and replace the existing dust data
@view
func add_dust(cell: Cell, dust: Dust) -> (cell: Cell) {
    alloc_locals;

    local new_cell: Cell;
    assert new_cell.class_hash = cell.class_hash;
    assert new_cell.dust_count = cell.dust_count + 1;
    assert new_cell.dust = dust;
    assert new_cell.ship_id = cell.ship_id;

    return (cell=new_cell);
}

// Add a dust in a given cell
// ! Removing a dust will decrement the dust count but keep the dust data
@view
func remove_dust(cell: Cell) -> (cell: Cell) {
    alloc_locals;

    with_attr error_message("Cell: No dust here") {
        let (dust_count) = get_dust_count(cell);
        assert_not_zero(dust_count);
    }

    local new_cell: Cell;
    assert new_cell.class_hash = cell.class_hash;
    assert new_cell.dust_count = cell.dust_count - 1;
    assert new_cell.dust = cell.dust;
    assert new_cell.ship_id = cell.ship_id;

    return (cell=new_cell);
}

// Returns the number of dust on a given cell
@view
func get_dust_count(cell: Cell) -> (dust_count: felt) {
    return (dust_count=cell.dust_count);
}

// Returns the dust on a given cell
@view
func get_dust(cell: Cell) -> (dust: Dust) {
    return (dust=cell.dust);
}

// Check if a cell contains dust
@view
func has_dust(cell: Cell) -> (has_dust: felt) {
    let (dust_count) = get_dust_count(cell);
    let has_dust = is_not_zero(dust_count);
    return (has_dust=has_dust);
}

// Check if a cell is free (contains no dust nor ship)
@view
func is_free(cell: Cell) -> (is_free: felt) {
    let (occupied) = is_occupied(cell);
    if (occupied == 0) {
        return (is_free=1);
    } else {
        return (is_free=0);
    }
}

// Check if a cell is occupied (contains dust and/or ship)
@view
func is_occupied(cell: Cell) -> (is_occupied: felt) {
    let (dust) = has_dust(cell);
    let (ship) = has_ship(cell);
    let is_occupied = is_not_zero(dust + ship);
    return (is_occupied=is_occupied);
}
