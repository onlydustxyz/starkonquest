%lang starknet

from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero

from contracts.models.common import Vector2

// ------------------
// STRUCTS
// ------------------
struct Dust {
    direction: Vector2,
}

struct Cell {
    dust_count: felt,
    dust: Dust,
    ship_id: felt,
}

// ------------------
// PUBLIC NAMESPACE
// ------------------
namespace cell_access {
    // create an empty cell
    func create() -> (cell: Cell) {
        alloc_locals;

        local cell: Cell;
        assert cell.dust_count = 0;
        assert cell.dust.direction = Vector2(0, 0);
        assert cell.ship_id = 0;

        return (cell=cell);
    }

    // Add a ship in a given cell
    func add_ship{cell: Cell}(ship_id: felt) {
        alloc_locals;

        let (ship_exists) = has_ship();
        with_attr error_message("Cell: There is already a ship") {
            assert ship_exists = 0;
        }

        local new_cell: Cell;
        assert new_cell.dust_count = cell.dust_count;
        assert new_cell.dust.direction = cell.dust.direction;
        assert new_cell.ship_id = ship_id;

        let cell = new_cell;
        return ();
    }

    // Remove a ship in a given cell
    func remove_ship{cell: Cell}() {
        alloc_locals;

        let (ship_exists) = has_ship();
        with_attr error_message("Cell: No ship here") {
            assert_not_zero(ship_exists);
        }

        local new_cell: Cell;
        assert new_cell.dust_count = cell.dust_count;
        assert new_cell.dust.direction = cell.dust.direction;
        assert new_cell.ship_id = 0;

        let cell = new_cell;
        return ();
    }

    // Get a ship on a given cell
    func get_ship{cell: Cell}() -> (ship_id: felt) {
        return (ship_id=cell.ship_id);
    }

    // Check if a given cell contains a ship
    func has_ship{cell: Cell}() -> (has_ship: felt) {
        let (ship_id) = get_ship();
        let has_ship = is_not_zero(ship_id);
        return (has_ship=has_ship);
    }

    // Add a dust in a given cell
    // ! Adding a dust will increment the dust count and replace the existing dust data
    func add_dust{cell: Cell}(dust: Dust) {
        alloc_locals;

        local new_cell: Cell;
        assert new_cell.dust_count = cell.dust_count + 1;
        assert new_cell.dust = dust;
        assert new_cell.ship_id = cell.ship_id;

        let cell = new_cell;
        return ();
    }

    // Add a dust in a given cell
    // ! Removing a dust will decrement the dust count but keep the dust data
    func remove_dust{cell: Cell}() {
        alloc_locals;

        with_attr error_message("Cell: No dust here") {
            let (dust_count) = get_dust_count();
            assert_not_zero(dust_count);
        }

        local new_cell: Cell;
        assert new_cell.dust_count = cell.dust_count - 1;
        assert new_cell.dust = cell.dust;
        assert new_cell.ship_id = cell.ship_id;

        let cell = new_cell;
        return ();
    }

    // Returns the number of dust on a given cell
    func get_dust_count{cell: Cell}() -> (dust_count: felt) {
        return (dust_count=cell.dust_count);
    }

    // Returns the dust on a given cell
    func get_dust{cell: Cell}() -> (dust: Dust) {
        return (dust=cell.dust);
    }

    // Check if a cell contains dust
    func has_dust{cell: Cell}() -> (has_dust: felt) {
        let (dust_count) = get_dust_count();
        let has_dust = is_not_zero(dust_count);
        return (has_dust=has_dust);
    }

    // Check if a cell is free (contains no dust nor ship)
    func is_free{cell: Cell}() -> (is_free: felt) {
        let (occupied) = is_occupied();
        if (occupied == 0) {
            return (is_free=1);
        } else {
            return (is_free=0);
        }
    }

    // Check if a cell is occupied (contains dust and/or ship)
    func is_occupied{cell: Cell}() -> (is_occupied: felt) {
        let (dust) = has_dust();
        let (ship) = has_ship();
        let is_occupied = is_not_zero(dust + ship);
        return (is_occupied=is_occupied);
    }
}
