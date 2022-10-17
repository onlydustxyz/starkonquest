%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.alloc import alloc
from contracts.ships.random_move_ship.library import RandomMoveShip
from contracts.models.common import Vector2
from contracts.libraries.cell import Cell, Dust

const RANDOM_CONTRACT_ADDRESS = 0x123;

@external
func test_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RandomMoveShip.constructor(RANDOM_CONTRACT_ADDRESS);

    let grid: Cell* = alloc();
    assert [grid] = Cell(1, Dust(Vector2(0, 0)), 0);

    let grid_len = 1;
    let ship_id = 1;

    // Generate a first round of random numbers
    %{ stop_mock = mock_call(ids.RANDOM_CONTRACT_ADDRESS, "generate_random_numbers", [1, 1, 1, 1, 1]) %}
    let (next_direction) = RandomMoveShip.move(grid_len, grid, 1);

    // Assert next_direction = Vector2(0, 0)
    assert next_direction.x = 0;
    assert next_direction.y = 0;

    // Change the generated random numbers to get a different random direction
    %{
        stop_mock()
        stop_mock = mock_call(ids.RANDOM_CONTRACT_ADDRESS, "generate_random_numbers", [3, 3, 3, 3, 3])
    %}
    let (next_direction) = RandomMoveShip.move(grid_len, grid, 1);

    // Assert next_direction = Vector2(-1, -1)
    assert next_direction.x + 1 = 0;
    assert next_direction.y + 1 = 0;
    return ();
}
