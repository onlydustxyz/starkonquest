%lang starknet

struct Vector2 {
    x: felt,
    y: felt,
}

struct Context {
    max_turn_count: felt,
    max_dust: felt,
    rand_contract: felt,
    ship_count: felt,
    ship_contracts: felt*,
}

struct ShipInit {
    address: felt,
    position: Vector2,
}

struct Player {
    player_address: felt,
    ship_address: felt,
}
