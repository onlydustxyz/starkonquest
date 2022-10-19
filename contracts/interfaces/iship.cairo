%lang starknet

from contracts.models.common import Vector2
from contracts.interfaces.icell import Cell

@contract_interface
namespace IShip {
    func move(grid_state_len: felt, grid_state: Cell*, ship_id: felt) -> (new_direction: Vector2) {
    }

    // ERC165
    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }
}
