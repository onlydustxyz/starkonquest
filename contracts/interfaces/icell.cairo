%lang starknet

from contracts.models.common import Vector2

// ------------------
// STRUCTS
// ------------------
struct Dust {
    direction: Vector2,
}

struct Cell {
    class_hash: felt,
    dust_count: felt,
    dust: Dust,
    ship_id: felt,
}

// ------------------
// INTERFACE
// ------------------
@contract_interface
namespace ICell {
    func create() -> (cell: Cell) {
    }

    func add_ship(cell: Cell, ship_id: felt) -> (cell: Cell) {
    }

    func remove_ship(cell: Cell) -> (cell: Cell) {
    }

    func get_ship(cell: Cell) -> (ship_id: felt) {
    }

    func has_ship(cell: Cell) -> (has_ship: felt) {
    }

    func add_dust(cell: Cell, dust: Dust) -> (cell: Cell) {
    }

    func remove_dust(cell: Cell) -> (cell: Cell) {
    }

    func get_dust_count(cell: Cell) -> (dust_count: felt) {
    }

    func get_dust(cell: Cell) -> (dust: Dust) {
    }

    func has_dust(cell: Cell) -> (has_dust: felt) {
    }

    func is_free(cell: Cell) -> (is_free: felt) {
    }

    func is_occupied(cell: Cell) -> (is_occupied: felt) {
    }
}

// ------------------
// PUBLIC NAMESPACE
// ------------------
namespace cell_access {
    func create{syscall_ptr: felt*}() -> (cell: Cell) {
        let (cell) = ICell.library_call_create(cell.class_hash);
        return (cell);
    }

    func add_ship{syscall_ptr: felt*, cell: Cell}(ship_id: felt) {
        let (cell) = ICell.library_call_add_ship(cell.class_hash, cell, ship_id);
        return ();
    }

    func remove_ship{syscall_ptr: felt*, cell: Cell}() {
        let (cell) = ICell.library_call_remove_ship(cell.class_hash, cell);
        return ();
    }

    func get_ship{syscall_ptr: felt*, cell: Cell}() -> (ship_id: felt) {
        let (ship_id) = ICell.library_call_get_ship(cell.class_hash, cell);
        return (ship_id);
    }

    func has_ship{syscall_ptr: felt*, cell: Cell}() -> (has_ship: felt) {
        let (has_ship) = ICell.library_call_has_ship(cell.class_hash, cell);
        return (has_ship);
    }

    func add_dust{syscall_ptr: felt*, cell: Cell}(dust: Dust) {
        let (cell) = ICell.library_call_add_dust(cell.class_hash, cell, dust);
        return ();
    }

    func remove_dust{syscall_ptr: felt*, cell: Cell}() {
        let (cell) = ICell.library_call_remove_dust(cell.class_hash, cell);
        return ();
    }

    func get_dust_count{syscall_ptr: felt*, cell: Cell}() -> (dust_count: felt) {
        let (dust_count) = ICell.library_call_get_dust_count(cell.class_hash, cell);
        return (dust_count);
    }

    func get_dust{syscall_ptr: felt*, cell: Cell}() -> (dust: Dust) {
        let (dust) = ICell.library_call_get_dust(cell.class_hash, cell);
        return (dust);
    }

    func has_dust{syscall_ptr: felt*, cell: Cell}() -> (has_dust: felt) {
        let (has_dust) = ICell.library_call_has_dust(cell.class_hash, cell);
        return (has_dust);
    }

    func is_free{syscall_ptr: felt*, cell: Cell}() -> (is_free: felt) {
        let (is_free) = ICell.library_call_is_free(cell.class_hash, cell);
        return (is_free);
    }

    func is_occupied{syscall_ptr: felt*, cell: Cell}() -> (is_occupied: felt) {
        let (is_occupied) = ICell.library_call_is_occupied(cell.class_hash, cell);
        return (is_occupied);
    }
}
